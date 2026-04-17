// lib/src/constants/app_constants.dart

class OrderStatus {
  static const String pending = 'Pending';
  static const String preparing = 'Preparing';
  static const String readyForPickup = 'Ready for Pickup';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';

  static const List<String> all = [
    pending,
    preparing,
    readyForPickup,
    completed,
    cancelled,
  ];

  static const List<String> active = [
    pending,
    preparing,
    readyForPickup,
  ];
}

class RiderStatus {
  static const String onboarding = 'onboarding';
  static const String pendingApproval = 'pending_approval';
  static const String active = 'active';
  static const String suspended = 'suspended';
}

class VenueTypeConstants {
  static const String canteen = 'canteen';
  static const String restaurant = 'restaurant';
  static const double defaultRadius = 1500.0; // 1.5km
}

class FirestoreCollections {
  static const String orders = 'Orders';
  static const String riders = 'Riders';
  static const String canteens = 'Canteens';
  static const String users = 'Users';
}
