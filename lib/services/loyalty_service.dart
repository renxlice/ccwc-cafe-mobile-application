import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/loyalty_program_model.dart';
import '../screens/models/user_model.dart';
import '../screens/models/loyalty_reward.dart';
import 'package:logger/logger.dart';

class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Add method to get user loyalty
  Stream<UserData?> getUserLoyalty(String userId) {
    return _firestore
        .collection('userLoyalty')
        .doc(userId)
        .snapshots()
        .map((snapshot) => 
            snapshot.exists ? UserData.fromMap(snapshot.data()!, snapshot.id) : null);
  }

  // Reward management
  Stream<List<LoyaltyReward>> getRewards() {
    try {
      return _firestore
          .collection('loyalty_rewards')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => LoyaltyReward.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      _logger.e('Error fetching rewards', error: e);
      return Stream.value([]);
    }
  }

  // Method to redeem reward with proof
  Future<String> redeemReward(
    String userId, 
    String rewardId, 
    int pointsRequired, 
    String rewardName
  ) async {
    try {
      // Additional authentication check
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('User authentication failed');
      }

      final claimCode = _generateClaimCode();
      
      await _firestore.runTransaction((transaction) async {
        // Explicit checks with detailed logging
        try {
          // Check reward stock
          final rewardDoc = await transaction.get(_firestore.collection('loyalty_rewards').doc(rewardId));
          if (!rewardDoc.exists) {
            print('Reward document does not exist');
            throw Exception('Reward not found');
          }

          final rewardData = rewardDoc.data()!;
          if (rewardData['stock'] <= 0) {
            print('Reward out of stock');
            throw Exception('Reward out of stock');
          }

          // Check user points
          final userDoc = await transaction.get(_firestore.collection('userLoyalty').doc(userId));
          if (!userDoc.exists) {
            print('User loyalty document does not exist');
            throw Exception('User loyalty not found');
          }

          final userData = userDoc.data()!;
          final currentPoints = userData['points'] ?? 0;
          if (currentPoints < pointsRequired) {
            print('Insufficient points: $currentPoints < $pointsRequired');
            throw Exception('Not enough points');
          }

          // Update reward stock
          transaction.update(_firestore.collection('loyalty_rewards').doc(rewardId), {
            'stock': FieldValue.increment(-1),
          });

          // Update user points
          transaction.update(_firestore.collection('userLoyalty').doc(userId), {
            'points': FieldValue.increment(-pointsRequired),
            'redeemedPoints': FieldValue.increment(pointsRequired),
            'redeemedRewards': FieldValue.arrayUnion([rewardId]),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Create redemption record
          final redemptionRef = _firestore.collection('rewardRedemptions').doc();
          transaction.set(redemptionRef, {
            'userId': userId,
            'rewardId': rewardId,
            'rewardName': rewardName,
            'pointsUsed': pointsRequired,
            'redeemedAt': FieldValue.serverTimestamp(),
            'isClaimed': false,
            'claimCode': claimCode,
          });

        } catch (e) {
          print('Transaction error details: $e');
          rethrow;
        }
      });
      
      return claimCode;
    } catch (e) {
      print('Redeem error details: $e');
      throw e;
    }
  }

  // Generate claim code method
  String _generateClaimCode() {
    final random = Random();
    return '${random.nextInt(9000) + 1000}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  // Method to get user redemptions
  Stream<List<RewardRedemption>> getUserRedemptions(String userId) {
    return _firestore.collection('rewardRedemptions')
      .where('userId', isEqualTo: userId)
      .orderBy('redeemedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RewardRedemption.fromMap(doc.data(), doc.id))
          .toList());
  }

  // Method to mark redemption as claimed
  Future<void> markRedemptionAsClaimed(String redemptionId) async {
    try {
      await _firestore.collection('rewardRedemptions').doc(redemptionId).update({
        'isClaimed': true,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error marking redemption as claimed', error: e);
      rethrow;
    }
  }

  Future<void> addReward(LoyaltyReward reward) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User harus login terlebih dahulu');
    }

    // Validasi dasar
    if (reward.name.isEmpty) throw Exception('Nama reward tidak boleh kosong');
    if (reward.pointsRequired < 0) throw Exception('Poin tidak boleh negatif');
    if (reward.stock < 0) throw Exception('Stok tidak boleh negatif');

    final rewardData = reward.toMap();
    rewardData['createdAt'] = FieldValue.serverTimestamp();
    rewardData['createdBy'] = currentUser.uid;

    await _firestore.collection('loyalty_rewards').add(rewardData);
    print('Reward berhasil ditambahkan');
    
  } on FirebaseException catch (e) {
    throw Exception('Gagal menambahkan reward: ${e.message}');
  } catch (e) {
    throw Exception('Gagal menambahkan reward: $e');
  }
}

  Future<void> updateReward(String rewardId, LoyaltyReward reward) async {
  try {
    // Validate reward data
    if (reward.name.isEmpty) {
      throw Exception('Reward name cannot be empty');
    }

    if (reward.pointsRequired < 0) {
      throw Exception('Points required cannot be negative');
    }

    if (reward.stock < 0) {
      throw Exception('Stock cannot be negative');
    }

    // Update the reward in Firestore
    await _firestore
        .collection('loyalty_rewards')
        .doc(rewardId)
        .update(reward.toMap());
    
    _logger.i('Reward updated successfully: ${reward.name}');
  } on FirebaseException catch (e) {
    _logger.e('Firebase error updating reward: ${e.code}', error: e);
    throw Exception('Failed to update reward: ${e.message}');
  } catch (e) {
    _logger.e('Error updating reward', error: e);
    throw Exception('Failed to update reward: $e');
  }
}

Future<void> toggleRewardStatus(String rewardId, bool isActive) async {
  try {
    await _firestore
        .collection('loyalty_rewards')
        .doc(rewardId)
        .update({
          'isActive': isActive,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
    
    _logger.i('Reward status updated: $rewardId, Active: $isActive');
  } on FirebaseException catch (e) {
    _logger.e('Firebase error toggling reward status: ${e.code}', error: e);
    throw Exception('Failed to toggle reward status: ${e.message}');
  } catch (e) {
    _logger.e('Error toggling reward status', error: e);
    throw Exception('Failed to toggle reward status: $e');
  }
}

Future<void> addPoints(String userId, int pointsToAdd) async {
  try {
    // Check if the user exists
    final userLoyaltyRef = _firestore.collection('userLoyalty').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userLoyaltyDoc = await transaction.get(userLoyaltyRef);
      
      if (!userLoyaltyDoc.exists) {
        // Create a new user loyalty document if it doesn't exist
        transaction.set(userLoyaltyRef, {
          'points': pointsToAdd,
          'totalPointsEarned': pointsToAdd,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user loyalty document
        transaction.update(userLoyaltyRef, {
          'points': FieldValue.increment(pointsToAdd),
          'totalPointsEarned': FieldValue.increment(pointsToAdd),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });

    print('Added $pointsToAdd points to user $userId'); 
  } catch (e) {
    print('Error adding points to user: $e'); 
    throw Exception('Failed to add loyalty points: $e');
  }
}

// Untuk user (hanya yang aktif)
Stream<List<LoyaltyReward>> getActiveRewards() {
  try {
    return _firestore
        .collection('loyalty_rewards')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoyaltyReward.fromMap(doc.data(), doc.id))
            .toList());
  } catch (e) {
    _logger.e('Error fetching active rewards', error: e);
    return Stream.value([]);
  }
}

// Untuk admin (semua rewards)
Stream<List<LoyaltyReward>> getAllRewards() {
    try {
      return _firestore
          .collection('loyalty_rewards')
          .snapshots()
          .map((snapshot) {
            _cachedRewards = snapshot.docs
                .map((doc) => LoyaltyReward.fromMap(doc.data(), doc.id))
                .toList();
            return _cachedRewards;
          })
          .handleError((error) {
            _logger.e('Error fetching all rewards', error: error);
            return _cachedRewards; 
          });
    } catch (e) {
      _logger.e('Error in getAllRewards stream setup', error: e);
      return Stream.value(_cachedRewards); 
    }
  }

// In LoyaltyService
int get activeRewardsCount {
  return _cachedRewards.where((r) => r.isActive).length;
}

// Initialize _cachedRewards in your service
List<LoyaltyReward> _cachedRewards = [];

Future<void> deleteReward(String rewardId) async {
  try {
    await _firestore.collection('loyalty_rewards').doc(rewardId).delete();
    _logger.i('Reward deleted successfully: $rewardId');
    
    // Remove from cached rewards if it exists
    _cachedRewards.removeWhere((reward) => reward.id == rewardId);
  } on FirebaseException catch (e) {
    _logger.e('Firebase error deleting reward: ${e.code}', error: e);
    throw Exception('Failed to delete reward: ${e.message}');
  } catch (e) {
    _logger.e('Error deleting reward', error: e);
    throw Exception('Failed to delete reward: $e');
  }
}
}