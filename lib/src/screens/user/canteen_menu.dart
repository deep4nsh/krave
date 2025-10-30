import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/canteen_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import 'cart_screen.dart';

class CanteenMenu extends StatelessWidget {
  final Canteen canteen;
  const CanteenMenu({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final cart = context.read<CartProvider>();

    // When entering a new canteen menu, clear the old cart.
    cart.clearCart();

    return Scaffold(
      appBar: AppBar(
        title: Text(canteen.name),
        actions: [CartIconWithBadge(canteen: canteen)],
      ),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: fs.streamMenuItems(canteen.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('This canteen has no menu items yet.'));
          }

          final groupedMenu = groupBy(items, (MenuItemModel item) => item.category ?? 'Other');

          return ListView.builder(
            itemCount: groupedMenu.length,
            itemBuilder: (context, index) {
              final category = groupedMenu.keys.elementAt(index);
              final categoryItems = groupedMenu[category]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(category, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  ...categoryItems.map((item) => MenuItemCard(item: item)).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class CartIconWithBadge extends StatelessWidget {
  final Canteen canteen;
  const CartIconWithBadge({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final navigator = Navigator.of(context);

    return Badge(
      label: Text(cart.totalQuantity.toString()),
      isLabelVisible: cart.itemCount > 0,
      child: IconButton(
        icon: const Icon(Icons.shopping_cart),
        onPressed: () {
          if (cart.items.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
            return;
          }
          navigator.push(MaterialPageRoute(builder: (_) => CartScreen(canteen: canteen)));
        },
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItem = cart.items[item.id];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: const Icon(Icons.fastfood, size: 40), // Placeholder icon
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('₹${item.price}'),
          trailing: cartItem == null
              ? ElevatedButton(onPressed: () => cart.addItem(item), child: const Text('Add'))
              : QuantityStepper(item: cartItem),
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final CartItem item;
  const QuantityStepper({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: () => cart.removeSingleItem(item.id)),
        Text(item.quantity.toString(), style: const TextStyle(fontSize: 18)),
        IconButton(icon: const Icon(Icons.add), onPressed: () => cart.addItem(MenuItemModel(id: item.id, name: item.name, price: item.price))),
      ],
    );
  }
}
