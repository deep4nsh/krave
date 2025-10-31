import 'package:flutter/foundation.dart';

class MenuItemModel {
  final String id;
  final String name;
  final int price;
  final bool available;
  final String? category;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.available = true,
    this.category,
  });

  // This is a robust, defensive factory constructor that will not crash.
  factory MenuItemModel.fromMap(String id, Map<String, dynamic> data) {
    try {
      // Safely parse the price, handling int, double, or even string.
      int parsedPrice = 0;
      final priceRaw = data['price'];
      if (priceRaw is int) {
        parsedPrice = priceRaw;
      } else if (priceRaw is double) {
        parsedPrice = priceRaw.toInt();
      } else if (priceRaw is String) {
        parsedPrice = int.tryParse(priceRaw) ?? 0;
      }

      return MenuItemModel(
        id: id,
        name: data['name'] as String? ?? 'Unnamed Item',
        price: parsedPrice,
        available: data['available'] as bool? ?? true,
        category: data['category'] as String?,
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE MenuItemModel !!!!!!');
      debugPrint('Document ID: $id | Data: $data');
      debugPrint('Error: $e');
      // Return a default/error state object instead of crashing
      return MenuItemModel(
        id: id,
        name: 'Error: Invalid Data',
        price: 0,
        category: 'Error',
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'available': available,
    'category': category,
  };
}
