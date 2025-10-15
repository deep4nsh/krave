// lib/models/menu_item.dart
class MenuItemModel {
  final String id;
  final String name;
  final int price;
  final bool available;
  final String? imageUrl;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.available = true,
    this.imageUrl,
  });

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> m) {
    return MenuItemModel(
      id: id,
      name: m['name'] ?? '',
      price: (m['price'] ?? 0).toInt(),
      available: m['available'] ?? true,
      imageUrl: m['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'available': available,
    'imageUrl': imageUrl,
  };
}