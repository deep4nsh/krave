import 'package:flutter/foundation.dart';

class Canteen {
  final String id;
  final String name;
  final String ownerId;
  final bool approved;
  final String? openingTime;
  final String? closingTime;

  Canteen({
    required this.id,
    required this.name,
    required this.ownerId,
    this.approved = false,
    this.openingTime,
    this.closingTime,
  });

  factory Canteen.fromMap(String id, Map<String, dynamic> data) {
    try {
      return Canteen(
        id: id,
        name: data['name'] as String? ?? 'Unnamed Canteen',
        ownerId: data['ownerId'] as String? ?? '', // ownerId is critical, but an empty string is a temporary safe default
        approved: data['approved'] as bool? ?? false,
        openingTime: data['opening_time'] as String?,
        closingTime: data['closing_time'] as String?,
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE Canteen !!!!!!');
      debugPrint('Document ID: $id | Data: $data');
      debugPrint('Error: $e');
      // Return a default/error state object instead of crashing
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
  };
}
