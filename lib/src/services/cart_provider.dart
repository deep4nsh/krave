import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';

class CartItem {
  final String id;
  final String name;
  final int price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  void increment() => quantity++;
  void decrement() => quantity--;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
  };
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(MenuItemModel menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items.update(menuItem.id, (existing) {
        existing.increment();
        return existing;
      });
    } else {
      _items.putIfAbsent(
        menuItem.id,
        () => CartItem(id: menuItem.id, name: menuItem.name, price: menuItem.price),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) {
        existing.decrement();
        return existing;
      });
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
