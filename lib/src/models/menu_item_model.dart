import 'package:flutter/foundation.dart';

class MenuItemModel {
  final String id;
  final String name;
  final int price;
  final bool available;
  final String? category;
  final String? photoUrl;
  final bool isVeg;
  
  // Professional Metadata
  final int? discountPrice;
  final int prepTime; // estimated minutes
  final List<String> tags; // ['Trending', 'Spicy', 'New']
  final String? description;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.available = true,
    this.category,
    this.photoUrl,
    this.isVeg = true,
    this.discountPrice,
    this.prepTime = 10,
    this.tags = const [],
    this.description,
  });

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> data) {
    try {
      int parsedPrice = (data['price'] ?? 0).toInt();
      int? parsedDiscount = data['discountPrice'] != null ? (data['discountPrice'] as num).toInt() : null;

      return MenuItemModel(
        id: id,
        name: data['name'] as String? ?? 'Unnamed Item',
        price: parsedPrice,
        available: data['available'] as bool? ?? true,
        category: data['category'] as String?,
        photoUrl: data['photoUrl'] as String?,
        isVeg: data['isVeg'] as bool? ?? true,
        discountPrice: parsedDiscount,
        prepTime: (data['prepTime'] ?? 10).toInt(),
        tags: List<String>.from(data['tags'] ?? []),
        description: data['description'] as String?,
      );
    } catch (e) {
      debugPrint('!!!!!! FAILED TO PARSE MenuItemModel !!!!!! ID: $id | Error: $e');
      return MenuItemModel(id: id, name: 'Error: Invalid Data', price: 0);
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'available': available,
    'category': category,
    'photoUrl': photoUrl,
    'isVeg': isVeg,
    'discountPrice': discountPrice,
    'prepTime': prepTime,
    'tags': tags,
    'description': description,
  };
}
