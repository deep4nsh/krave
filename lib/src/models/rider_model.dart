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
  final int onboardingStep; // 1 to 6
  final String? vehicleType; // bike, cycle, scooter
  final String? city;
  final Map<String, dynamic> kycDetails;
  final int trainingScore;
  final bool agreementAccepted;

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
    this.trainingScore = 0,
    this.agreementAccepted = false,
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
      trainingScore: m['trainingScore'] as int? ?? 0,
      agreementAccepted: m['agreementAccepted'] as bool? ?? false,
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
        'trainingScore': trainingScore,
        'agreementAccepted': agreementAccepted,
      };

  RiderModel copyWith({
    String? name,
    String? email,
    bool? isActive,
    String? fcmToken,
    String? status,
    int? onboardingStep,
    String? vehicleType,
    String? city,
    Map<String, dynamic>? kycDetails,
    int? trainingScore,
    bool? agreementAccepted,
  }) {
    return RiderModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      status: status ?? this.status,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      vehicleType: vehicleType ?? this.vehicleType,
      city: city ?? this.city,
      kycDetails: kycDetails ?? this.kycDetails,
      trainingScore: trainingScore ?? this.trainingScore,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
    );
  }
}
