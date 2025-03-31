class RewardRedemption {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final int pointsUsed;
  final DateTime redeemedAt;
  final bool isClaimed;
  final DateTime? claimedAt;
  final String? claimCode;
  final String rewardImageUrl;

  RewardRedemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.pointsUsed,
    required this.redeemedAt,
    this.isClaimed = false,
    this.claimedAt,
    this.claimCode,
    required this.rewardImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'pointsUsed': pointsUsed,
      'redeemedAt': redeemedAt,
      'isClaimed': isClaimed,
      'claimedAt': claimedAt,
      'claimCode': claimCode,
      'rewardImageUrl': rewardImageUrl, 
    };
  }

  factory RewardRedemption.fromMap(Map<String, dynamic> data, String id) {
    return RewardRedemption(
      id: id,
      userId: data['userId'] ?? '',
      rewardId: data['rewardId'] ?? '',
      rewardName: data['rewardName'] ?? '',
      pointsUsed: data['pointsUsed'] ?? 0,
      redeemedAt: data['redeemedAt']?.toDate() ?? DateTime.now(),
      isClaimed: data['isClaimed'] ?? false,
      claimedAt: data['claimedAt']?.toDate(),
      claimCode: data['claimCode'],
      rewardImageUrl: data['rewardImageUrl'] ?? '',
    );
  }
}