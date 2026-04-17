import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class KraveUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'user', 'admin', 'owner', 'rider'
  final bool approved;
  final String? canteenId;
  final String? fcmToken;
  
  // New Professional Fields
  final String? phone;
  final String? profilePic;
  final double walletBalance;
  final Map<String, dynamic>? address; // { hostel: 'Ramanujan', room: '101', spec: 'Near lift' }
  final DateTime createdAt;
  final DateTime updatedAt;

  KraveUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.approved = false,
    this.canteenId,
    this.fcmToken,
    this.phone,
    this.profilePic,
    this.walletBalance = 0.0,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KraveUser.fromMap(String id, Map<String, dynamic> data) {
    try {
      return KraveUser(
        id: id,
        name: data['name'] as String? ?? 'Unnamed User',
        email: data['email'] as String? ?? '',
        role: data['role'] as String? ?? 'user',
        approved: data['approved'] as bool? ?? false,
        canteenId: data['canteenId'] as String?,
        fcmToken: data['fcmToken'] as String?,
        phone: data['phone'] as String?,
        profilePic: data['profilePic'] as String?,
        walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
        address: data['address'] as Map<String, dynamic>?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE KraveUser !!!!!! ID: $id | Error: $e');
      return KraveUser(
        id: id,
        name: 'Error: Invalid Data',
        email: '',
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role,
    'approved': approved,
    'canteenId': canteenId,
    'fcmToken': fcmToken,
    'phone': phone,
    'profilePic': profilePic,
    'walletBalance': walletBalance,
    'address': address,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  KraveUser copyWith({
    String? name,
    String? email,
    String? role,
    bool? approved,
    String? canteenId,
    String? fcmToken,
    String? phone,
    String? profilePic,
    double? walletBalance,
    Map<String, dynamic>? address,
  }) {
    return KraveUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      canteenId: canteenId ?? this.canteenId,
      fcmToken: fcmToken ?? this.fcmToken,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      walletBalance: walletBalance ?? this.walletBalance,
      address: address ?? this.address,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
