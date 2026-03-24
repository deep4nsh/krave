import 'package:cloud_firestore/cloud_firestore.dart';

class RiderModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final String? fcmToken;
  final DateTime createdAt;

  RiderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.isActive = false,
    this.fcmToken,
    required this.createdAt,
  });

  factory RiderModel.fromMap(String id, Map<String, dynamic> m) {
    return RiderModel(
      id: id,
      name: m['name'] as String? ?? 'Rider',
      email: m['email'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      isActive: m['isActive'] as bool? ?? false,
      fcmToken: m['fcmToken'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'isActive': isActive,
        'fcmToken': fcmToken,
        'createdAt': createdAt,
      };

  RiderModel copyWith({bool? isActive, String? fcmToken}) {
    return RiderModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
