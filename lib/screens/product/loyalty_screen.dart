import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../services/loyalty_service.dart';
import '../models/loyalty_program_model.dart';
import '../models/user_model.dart';
import '../models/loyalty_reward.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  Widget _buildImageWidget(String? imageData, {double size = 40}) {
    if (imageData == null || imageData.isEmpty) {
      return Icon(Icons.broken_image, size: size, color: Colors.grey[400]);
    }

    try {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(size),
        );
      }
      else if (imageData.startsWith('data:image')) {
        final bytes = base64Decode(imageData.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(size),
        );
      }
      else {
        try {
          final bytes = base64Decode(imageData);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(size),
          );
        } catch (_) {
          return _buildErrorWidget(size);
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return _buildErrorWidget(size);
    }
  }

  Widget _buildErrorWidget(double size) {
    return Center(
      child: Icon(Icons.broken_image, size: size, color: Colors.grey[400]),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Loyalty Program Rules',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint('Earn points for every completed order'),
              _buildBulletPoint('1 point = Rp.10.000 in reward value'),
              _buildBulletPoint('Points can be redeemed for rewards from the available selection'),
              _buildBulletPoint('Rewards may be limited in quantity and subject to availability'),
              _buildBulletPoint('Points have no cash value and cannot be transferred'),
              const SizedBox(height: 20),
              const Text(
                'Redemption Process',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint('Select the reward you wish to redeem'),
              _buildBulletPoint('Ensure you have sufficient points for the reward'),
              _buildBulletPoint('Present the redemption code to staff when claiming'),
              _buildBulletPoint('Rewards must be claimed within 30 days of redemption'),
              const SizedBox(height: 20),
              const Text(
                'General Terms',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint('We reserve the right to modify or terminate the program at any time'),
              _buildBulletPoint('Fraud or abuse may result in termination of membership'),
              _buildBulletPoint('All decisions regarding point accrual and redemption are final'),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text(
                    'I UNDERSTAND',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Icon(Icons.circle, size: 8, color: Colors.brown),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loyalty Program')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.brown),
              const SizedBox(height: 20),
              const Text(
                'Login Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please login to access the loyalty program',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        backgroundColor: Colors.brown[700],
      ),
      body: StreamBuilder<UserData?>(
        stream: Provider.of<LoyaltyService>(context).getUserLoyalty(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data ?? UserData(
            uid: user.uid,
            name: '',
            bio: '',
            photoURL: '',
            points: 0,
            redeemedPoints: 0,
            redeemedRewards: [],
            lastUpdated: DateTime.now(),
          );

          return Column(
            children: [
              Column(
                children: [
                  // Points Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.brown[700]!, Colors.brown[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(128),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR POINTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userData.points.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Redeemed Points',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  userData.redeemedPoints.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Total Points',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  (userData.points + userData.redeemedPoints).toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // How it works section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How it works',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.brown
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Earn points for every completed order\n'
                              '• Redeem points for exclusive rewards\n'
                              '• Points never expire',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _showTermsAndConditions(context);
                              },
                              child: const Text('View full terms and conditions', style: TextStyle(color: Colors.brown)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Rewards section header with history button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Rewards',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.brown,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RedemptionHistoryScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.history, size: 18, color: Colors.brown),
                          SizedBox(width: 4),
                          Text(
                            'History',
                            style: TextStyle(color: Colors.brown),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildRewardsList(context, userData),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardsList(BuildContext context, UserData userData) {
    final loyaltyService = Provider.of<LoyaltyService>(context);
    final isAdmin = false;

    return StreamBuilder<List<LoyaltyReward>>(
      stream: isAdmin ? loyaltyService.getRewards() : loyaltyService.getActiveRewards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              isAdmin 
                ? 'No rewards available at the moment'
                : 'No active rewards available right now',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final rewards = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            final canRedeem = userData.points >= reward.pointsRequired && reward.stock > 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: isAdmin && !reward.isActive ? Colors.grey[200] : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Reward image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(reward.imageUrl, size: 80),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reward details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isAdmin && !reward.isActive ? Colors.grey : Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reward.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isAdmin && !reward.isActive 
                                ? Colors.grey[500] 
                                : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(51),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${reward.pointsRequired} pts',
                                  style: TextStyle(
                                    color: isAdmin && !reward.isActive 
                                      ? Colors.grey 
                                      : Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (reward.stock > 0)
                                Text(
                                  '${reward.stock} left',
                                  style: TextStyle(
                                    color: isAdmin && !reward.isActive 
                                      ? Colors.grey[500] 
                                      : Colors.brown[600],
                                    fontSize: 12,
                                  ),
                                )
                              else
                                const Text(
                                  'Out of stock',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canRedeem && reward.isActive)
                      IconButton(
                        icon: const Icon(Icons.redeem, color: Colors.amber),
                        onPressed: () async {
                          try {
                            final claimCode = await loyaltyService.redeemReward(
                              userData.uid,
                              reward.id,
                              reward.pointsRequired,
                              reward.name,
                            );
                            
                            if (context.mounted) {
                              _showRedemptionProof(
                                context, 
                                reward, 
                                claimCode,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to redeem: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    if (isAdmin && !reward.isActive)
                      const Icon(Icons.visibility_off, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRedemptionProof(
    BuildContext context, 
    LoyaltyReward reward,
    String claimCode,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reward Redeemed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(reward.imageUrl, size: 100),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.brown
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Show this code to cashier to claim your reward:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      claimCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This reward will be available in your redemption history',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CLOSE',
                          style: TextStyle(color: Colors.brown),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RedemptionHistoryScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'VIEW HISTORY',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RedemptionHistoryScreen extends StatelessWidget {
  const RedemptionHistoryScreen({Key? key}) : super(key: key);

  Widget _buildImageWidget(String? imageData, {double size = 40}) {
    if (imageData == null || imageData.isEmpty) {
      return Icon(Icons.card_giftcard, size: size, color: Colors.grey[400]);
    }

    try {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(size),
        );
      }
      else if (imageData.startsWith('data:image')) {
        final bytes = base64Decode(imageData.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(size),
        );
      }
      else {
        try {
          final bytes = base64Decode(imageData);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(size),
          );
        } catch (_) {
          return _buildErrorWidget(size);
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return _buildErrorWidget(size);
    }
  }

  Widget _buildErrorWidget(double size) {
    return Icon(Icons.card_giftcard, size: size, color: Colors.grey[400]);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.brown[400]),
              SizedBox(height: 16),
              Text(
                'Login Required',
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.brown),
              ),
              SizedBox(height: 8),
              Text(
                'Please login to view your redemption history',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption History'),
        backgroundColor: Colors.brown[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown[50]!,
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<List<RewardRedemption>>(
          stream: Provider.of<LoyaltyService>(context).getUserRedemptions(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[700]!),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No Redemption History',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your redeemed rewards will appear here',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final redemptions = snapshot.data!;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.brown[700]),
                      SizedBox(width: 8),
                      Text(
                        'Your Redemptions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.brown[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${redemptions.length} items',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: redemptions.length,
                    itemBuilder: (context, index) {
                      final redemption = redemptions[index];
                      final isClaimed = redemption.isClaimed;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (!isClaimed) {
                              _showRedemptionDetails(context, redemption);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Reward Image
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: isClaimed 
                                      ? Colors.green[50]
                                      : Colors.amber[50],
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildImageWidget(redemption.rewardImageUrl, size: 70),
                                      ),
                                      if (isClaimed)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Reward Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        redemption.rewardName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown[800],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Redeemed: ${DateFormat('MMM dd, yyyy - HH:mm').format(redemption.redeemedAt)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (isClaimed)
                                        Text(
                                          'Claimed: ${DateFormat('MMM dd, yyyy - HH:mm').format(redemption.claimedAt!)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.green[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Points and Code
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '-${redemption.pointsUsed} pts',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!isClaimed) ...[
                                      SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          redemption.claimCode ?? 'N/A',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.amber[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRedemptionDetails(BuildContext context, RewardRedemption redemption) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Redemption Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.brown[700],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber[50],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(redemption.rewardImageUrl, size: 120),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  redemption.rewardName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.brown[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.credit_score,
                label: 'Points Used',
                value: '-${redemption.pointsUsed} pts',
                color: Colors.red[700]!,
              ),
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Redeemed On',
                value: DateFormat('MMM dd, yyyy - HH:mm').format(redemption.redeemedAt),
                color: Colors.grey[700]!,
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Redemption Code',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Center(
                  child: Text(
                    redemption.claimCode ?? 'N/A',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Show this code to the cashier to claim your reward',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'UNDERSTOOD',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}