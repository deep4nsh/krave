// lib/src/utils/location_helper.dart
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Calculates the distance between two points in meters using the Haversine formula.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Checks if a user is within the delivery radius of a venue.
  static bool isWithinRadius({
    required double userLat,
    required double userLng,
    required double venueLat,
    required double venueLng,
    required double radiusInMeters,
  }) {
    double distance = calculateDistance(userLat, userLng, venueLat, venueLng);
    return distance <= radiusInMeters;
  }

  /// Request location permissions and get current position.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }
}
