// lib/models/user_model.dart
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

  factory KraveUser.fromMap(String id, Map<String, dynamic> m) {
    return KraveUser(
      id: id,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      role: m['role'] ?? 'user',
      approved: m['approved'] ?? false,
      canteenId: m['canteenId'],
      fcmToken: m['fcmToken'],
    );
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