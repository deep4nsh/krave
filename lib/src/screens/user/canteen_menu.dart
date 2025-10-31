import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/canteen_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import 'cart_screen.dart';

// 1. CONVERTED TO STATEFULWIDGET TO FIX THE `setState` ERROR
class CanteenMenu extends StatefulWidget {
  final Canteen canteen;
  const CanteenMenu({super.key, required this.canteen});

  @override
  State<CanteenMenu> createState() => _CanteenMenuState();
}

class _CanteenMenuState extends State<CanteenMenu> {

  @override
  void initState() {
    super.initState();
    // 2. MOVED `clearCart` to `initState`
    // We use a post-frame callback to ensure the context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear the cart from any previous canteen when entering a new menu.
      context.read<CartProvider>().clearCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.canteen.name),
        actions: [CartIconWithBadge(canteen: widget.canteen)],
      ),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: fs.streamMenuItems(widget.canteen.id),
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
                  // FIX: Removed unnecessary .toList()
                  ...categoryItems.map((item) => MenuItemCard(item: item)),
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
          final cartItems = cart.items.values.map((ci) => {
                'id': ci.id,
                'name': ci.name,
                'price': ci.price,
                'qty': ci.quantity,
              }).toList();
          navigator.push(
            MaterialPageRoute(
              builder: (_) => CartScreen(
                canteen: canteen,
                cartItems: cartItems,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 3. REBUILT MenuItemCard TO FIX THE LAYOUT ERROR
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
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.fastfood, size: 40, color: Colors.deepOrange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text('₹${item.price}'),
                ],
              ),
            ),
            cartItem == null
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => cart.addItem(item),
                    child: const Text('Add'),
                  )
                : QuantityStepper(item: cartItem),
          ],
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
