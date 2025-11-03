import 'package:flutter/foundation.dart';

class KraveUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool approved;
  final String? canteenId;
  final String? fcmToken;

  KraveUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.approved = false,
    this.canteenId,
    this.fcmToken,
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
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE KraveUser !!!!!!');
      debugPrint('Document ID: $id | Data: $data');
      debugPrint('Error: $e');
      // Return a default/error state object instead of crashing
      return KraveUser(
        id: id,
        name: 'Error: Invalid Data',
        email: '',
        role: 'user',
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
  };
}
