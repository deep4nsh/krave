// lib/models/menu_item.dart
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

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> m) {
    // Make price parsing robust to int/double/string/null values
    final dynamic priceRaw = m['price'] ?? 0;
    int parsedPrice;
    if (priceRaw is int) {
      parsedPrice = priceRaw;
    } else if (priceRaw is double) {
      parsedPrice = priceRaw.toInt();
    } else if (priceRaw is String) {
      parsedPrice = int.tryParse(priceRaw) ?? 0;
    } else {
      parsedPrice = 0;
    }

    return MenuItemModel(
      id: id,
      name: m['name'] ?? '',
      price: parsedPrice,
      available: m['available'] ?? true,
      category: m['category'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'available': available,
    'category': category,
  };
}
