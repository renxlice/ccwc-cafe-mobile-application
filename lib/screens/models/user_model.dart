import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  
  UserModel({required this.uid});

  void logout() {
    // Logika untuk logout, misalnya menghapus token atau mengubah status pengguna
    print('User with uid $uid has logged out.');
  }
}

class UserData {
  final String uid;
  final String name;
  final String bio;
  final String photoURL;
  final int points;
  final int redeemedPoints;
  final List<String> redeemedRewards;
  final DateTime lastUpdated;
  
  UserData({
    required this.uid, 
    required this.name, 
    required this.bio, 
    required this.photoURL,
    required this.points,
    required this.redeemedPoints,
    required this.redeemedRewards,
    required this.lastUpdated,
  });

  factory UserData.fromMap(Map<String, dynamic> data, String id) {
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

  Map<String, dynamic> toMap() {
    return {
      'uid' : uid,
      'name': name,
      'bio': bio,
      'photoURL': photoURL,
      'points': points,
      'redeemedPoints': redeemedPoints,
      'redeemedRewards': redeemedRewards,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}