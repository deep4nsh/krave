// lib/screens/user/canteen_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/canteen_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import 'cart_screen.dart';

class CanteenMenu extends StatefulWidget {
  final Canteen canteen;
  const CanteenMenu({Key? key, required this.canteen}) : super(key: key);

  @override
  State<CanteenMenu> createState() => _CanteenMenuState();
}

class _CanteenMenuState extends State<CanteenMenu> {
  List<Map<String, dynamic>> cart = [];

  void addToCart(MenuItemModel item) {
    final foundIndex = cart.indexWhere((e) => e['id'] == item.id);
    if (foundIndex >= 0) {
      cart[foundIndex]['qty'] += 1;
    } else {
      cart.add({'id': item.id, 'name': item.name, 'price': item.price, 'qty': 1});
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(widget.canteen.name), actions: [
        IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {
          if (cart.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(canteen: widget.canteen, cartItems: cart)));
        })
      ]),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: fs.streamMenuItems(widget.canteen.id),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No items.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('₹${it.price}'),
                  trailing: ElevatedButton(onPressed: () => addToCart(it), child: const Text('Add')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}