import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/models/user_model.dart';

class DatabaseService {
  final String id;

  DatabaseService({required this.id});

  // Collection reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  // Update user data
  Future<void> updateUserData({
    required String name,
    required String bio,
    required String photoURL,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is not logged in. Preventing access to Firestore.");
      return;
    }

    try {
      await userCollection.doc(user.uid).set({
        'name': name,
        'bio': bio,
        'photoURL': photoURL,
        'points': 0,          // Add default points
        'redeemedPoints': 0,  // Add default redeemedPoints
        'redeemedRewards': [], // Add default redeemedRewards
        'lastUpdated': FieldValue.serverTimestamp(), // Add timestamp
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        print("Firestore permission denied: You don't have access to update user data.");
      } else {
        print("Error updating user data: ${e.message}");
      }
    } catch (e) {
      print("Unknown error while updating user data: $e");
    }
  }

  // Get user data as Stream
  Stream<UserData> get userData {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is not logged in. Preventing access to Firestore.");
      return Stream.value(UserData(
        uid: '',
        name: '',
        bio: '',
        photoURL: '',
        points: 0,
        redeemedPoints: 0,
        redeemedRewards: [],
        lastUpdated: DateTime.now(),
      ));
    }

    return userCollection.doc(user.uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return UserData(
          uid: user.uid,
          name: '',
          bio: '',
          photoURL: '',
          points: 0,
          redeemedPoints: 0,
          redeemedRewards: [],
          lastUpdated: DateTime.now(),
        );
      }
      try {
        return _userDataFromSnapshot(snapshot);
      } catch (e) {
        print("Error parsing user data: $e");
        return UserData(
          uid: user.uid,
          name: '',
          bio: '',
          photoURL: '',
          points: 0,
          redeemedPoints: 0,
          redeemedRewards: [],
          lastUpdated: DateTime.now(),
        );
      }
    }).handleError((error) {
      print("Error in Firestore stream: $error");
    });
  }

  // Convert Firestore snapshot to UserData
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data();
    if (data == null || data is! Map<String, dynamic>) {
      print("Invalid data format for user ${snapshot.id}");
      return UserData(
        uid: id,
        name: '',
        bio: '',
        photoURL: '',
        points: 0,
        redeemedPoints: 0,
        redeemedRewards: [],
        lastUpdated: DateTime.now(),
      );
    }
    return UserData(
      uid: id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      photoURL: data['photoURL'] ?? '',
      points: data['points'] ?? 0,
      redeemedPoints: data['redeemedPoints'] ?? 0,
      redeemedRewards: List<String>.from(data['redeemedRewards'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}