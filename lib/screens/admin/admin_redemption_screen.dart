import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/loyalty_service.dart';
import '../models/loyalty_reward.dart';
import '../models/loyalty_program_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRedemptionScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminRedemptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reward Redemptions',
                  style: TextStyle(
                    color: Colors.brown,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify customer reward claims',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchField(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Recent Redemptions Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Recent Redemptions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Icon(Icons.history, color: Colors.brown),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Redemptions List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRecentRedemptions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Enter Claim Code',
          prefixIcon: const Icon(Icons.search, color: Colors.brown),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check, color: Colors.brown),
            onPressed: () {
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onSubmitted: (code) {
          _verifyRedemption(context, code);
        },
      ),
    );
  }

  Widget _buildRecentRedemptions(BuildContext context) {
    return Consumer<LoyaltyService>(
      builder: (context, loyaltyService, child) {
        return StreamBuilder<List<RewardRedemption>>(
          stream: _firestore.collection('rewardRedemptions')
            .orderBy('redeemedAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => RewardRedemption.fromMap(doc.data(), doc.id))
                .toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.brown));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No recent redemptions',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final redemptions = snapshot.data!;

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: redemptions.length,
              itemBuilder: (context, index) {
                final redemption = redemptions[index];
                final isClaimed = redemption.isClaimed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isClaimed 
                            ? Colors.green[50] 
                            : Colors.amber[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isClaimed 
                            ? Icons.verified 
                            : Icons.pending_actions,
                        color: isClaimed 
                            ? Colors.green 
                            : Colors.amber,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      redemption.rewardName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${redemption.claimCode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'User: ${redemption.userId.substring(0, 8)}...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    trailing: isClaimed
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'CLAIMED',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              loyaltyService.markRedemptionAsClaimed(redemption.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'VERIFY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _verifyRedemption(BuildContext context, String code) async {
    final loyaltyService = Provider.of<LoyaltyService>(context, listen: false);
    final snapshot = await _firestore.collection('rewardRedemptions')
      .where('claimCode', isEqualTo: code)
      .limit(1)
      .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid claim code'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final redemption = RewardRedemption.fromMap(
      snapshot.docs.first.data(), 
      snapshot.docs.first.id,
    );

    if (redemption.isClaimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This reward has already been claimed'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Redemption',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.rewardName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Code:', redemption.claimCode ?? 'N/A'),
                    _buildDetailRow('User:', '${redemption.userId.substring(0, 8)}...'),
                    _buildDetailRow('Points:', '${redemption.pointsUsed}'),
                    _buildDetailRow(
                      'Redeemed:', 
                    DateFormat('dd MMM yyyy HH:mm').format(redemption.redeemedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await loyaltyService.markRedemptionAsClaimed(redemption.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Redemption verified successfully'),
                          backgroundColor: Colors.green[400],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CONFIRM'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}