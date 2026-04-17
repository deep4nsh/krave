import 'package:flutter/foundation.dart';

enum VenueType { canteen, restaurant }

class Canteen {
  final String id;
  final String name;
  final String ownerId;
  final bool approved;
  final String? openingTime;
  final String? closingTime;
  final VenueType type;
  final double latitude;
  final double longitude;
  final double deliveryRadius; // in meters

  Canteen({
    required this.id,
    required this.name,
    required this.ownerId,
    this.approved = false,
    this.openingTime,
    this.closingTime,
    this.type = VenueType.canteen,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.deliveryRadius = 1000.0, // Default 1km
  });

  factory Canteen.fromMap(String id, Map<String, dynamic> data) {
    try {
      return Canteen(
        id: id,
        name: data['name'] as String? ?? 'Unnamed Venue',
        ownerId: data['ownerId'] as String? ?? '',
        approved: data['approved'] as bool? ?? false,
        openingTime: data['opening_time'] as String?,
        closingTime: data['closing_time'] as String?,
        type: data['type'] == 'restaurant' ? VenueType.restaurant : VenueType.canteen,
        latitude: (data['latitude'] ?? 0.0).toDouble(),
        longitude: (data['longitude'] ?? 0.0).toDouble(),
        deliveryRadius: (data['deliveryRadius'] ?? 1000.0).toDouble(),
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE Venue !!!!!!');
      debugPrint('Document ID: $id | Data: $data');
      debugPrint('Error: $e');
      return Canteen(
        id: id,
        name: 'Error: Invalid Data',
        ownerId: '',
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerId': ownerId,
    'approved': approved,
    'opening_time': openingTime,
    'closing_time': closingTime,
    'type': type == VenueType.restaurant ? 'restaurant' : 'canteen',
    'latitude': latitude,
    'longitude': longitude,
    'deliveryRadius': deliveryRadius,
  };
}
