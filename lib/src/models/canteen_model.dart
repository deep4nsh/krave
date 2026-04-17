import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum VenueType { canteen, restaurant }
enum VenueStatus { open, closed, busy }

class Canteen {
  final String id;
  final String name;
  final String ownerId;
  final bool approved;
  final String? openingTime;
  final String? closingTime;
  final VenueType type;
  final VenueStatus status;
  
  // Professional Metadata
  final String? image;
  final double rating;
  final int reviewCount;
  final List<String> categories;
  final int avgPrepTime; // in minutes
  
  // Logistics
  final double latitude;
  final double longitude;
  final String? address;
  final double deliveryRadius; // in meters
  
  final DateTime createdAt;

  Canteen({
    required this.id,
    required this.name,
    required this.ownerId,
    this.approved = false,
    this.openingTime,
    this.closingTime,
    this.type = VenueType.canteen,
    this.status = VenueStatus.open,
    this.image,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.categories = const [],
    this.avgPrepTime = 15,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address,
    this.deliveryRadius = 1000.0,
    required this.createdAt,
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
        status: _parseStatus(data['status']),
        image: data['image'] as String?,
        rating: (data['rating'] ?? 0.0).toDouble(),
        reviewCount: (data['reviewCount'] ?? 0).toInt(),
        categories: List<String>.from(data['categories'] ?? []),
        avgPrepTime: (data['avgPrepTime'] ?? 15).toInt(),
        latitude: (data['latitude'] ?? 0.0).toDouble(),
        longitude: (data['longitude'] ?? 0.0).toDouble(),
        address: data['address'] as String?,
        deliveryRadius: (data['deliveryRadius'] ?? 1000.0).toDouble(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE Canteen !!!!!! ID: $id | Error: $e');
      return Canteen(
        id: id,
        name: 'Error: Invalid Data',
        ownerId: '',
        createdAt: DateTime.now(),
      );
    }
  }

  static VenueStatus _parseStatus(String? s) {
    switch (s) {
      case 'closed': return VenueStatus.closed;
      case 'busy': return VenueStatus.busy;
      default: return VenueStatus.open;
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerId': ownerId,
    'approved': approved,
    'opening_time': openingTime,
    'closing_time': closingTime,
    'type': type == VenueType.restaurant ? 'restaurant' : 'canteen',
    'status': status.name,
    'image': image,
    'rating': rating,
    'reviewCount': reviewCount,
    'categories': categories,
    'avgPrepTime': avgPrepTime,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'deliveryRadius': deliveryRadius,
    'createdAt': createdAt,
  };
}
