import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyReward {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int pointsRequired;
  final int stock;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;

  LoyaltyReward({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pointsRequired,
    required this.stock,
    this.isActive = true,
    this.isDeleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'pointsRequired': pointsRequired,
      'stock': stock,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
    };
  }

  factory LoyaltyReward.fromMap(Map<String, dynamic> data, String id) {
    return LoyaltyReward(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pointsRequired: data['pointsRequired'] ?? 0,
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}