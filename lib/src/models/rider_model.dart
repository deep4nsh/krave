import 'package:cloud_firestore/cloud_firestore.dart';

class RiderModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final String? fcmToken;
  final DateTime createdAt;

  final String status; // 'onboarding', 'pending_approval', 'active', 'suspended'
  final int onboardingStep;
  final String? vehicleType;
  final String? city;
  final Map<String, dynamic> kycDetails;
  
  // Professional Stats
  final double rating;
  final int totalDeliveries;
  final int totalEarnings; // in Paisa or lowest currency unit
  final Map<String, dynamic>? currentLocation; // { lat, lng, updatedAt }

  RiderModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.isActive = false,
    this.fcmToken,
    required this.createdAt,
    this.status = 'onboarding',
    this.onboardingStep = 1,
    this.vehicleType,
    this.city,
    this.kycDetails = const {},
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.currentLocation,
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
      status: m['status'] as String? ?? 'onboarding',
      onboardingStep: m['onboardingStep'] as int? ?? 1,
      vehicleType: m['vehicleType'] as String?,
      city: m['city'] as String?,
      kycDetails: m['kycDetails'] as Map<String, dynamic>? ?? {},
      rating: (m['rating'] ?? 0.0).toDouble(),
      totalDeliveries: (m['totalDeliveries'] ?? 0).toInt(),
      totalEarnings: (m['totalEarnings'] ?? 0).toInt(),
      currentLocation: m['currentLocation'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'isActive': isActive,
        'fcmToken': fcmToken,
        'createdAt': createdAt,
        'status': status,
        'onboardingStep': onboardingStep,
        'vehicleType': vehicleType,
        'city': city,
        'kycDetails': kycDetails,
        'rating': rating,
        'totalDeliveries': totalDeliveries,
        'totalEarnings': totalEarnings,
        'currentLocation': currentLocation,
      };

  RiderModel copyWith({
    String? name,
    bool? isActive,
    String? fcmToken,
    String? status,
    int? onboardingStep,
    double? rating,
    int? totalDeliveries,
    int? totalEarnings,
    Map<String, dynamic>? currentLocation,
  }) {
    return RiderModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      status: status ?? this.status,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      vehicleType: vehicleType,
      city: city,
      kycDetails: kycDetails,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
