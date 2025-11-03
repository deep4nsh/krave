import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/canteen_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../widgets/gradient_background.dart';
import 'cart_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().clearCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows the gradient to show behind the AppBar
      appBar: AppBar(
        title: Text(widget.canteen.name),
        backgroundColor: Colors.transparent, // Make AppBar see-through
        elevation: 0,
      ),
      body: GradientBackground(
        child: StreamBuilder<List<MenuItemModel>>(
          stream: fs.streamMenuItems(widget.canteen.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('An error occurred: ${snap.error}'));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('This canteen has no menu items yet.'));
            }

            final groupedMenu = groupBy(items, (MenuItemModel item) => item.category ?? 'Other');

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, bottom: 100), // Padding to avoid FAB and AppBar
              itemCount: groupedMenu.length,
              itemBuilder: (context, index) {
                final category = groupedMenu.keys.elementAt(index);
                final categoryItems = groupedMenu[category]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: Text(category, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    ...categoryItems.map((item) => AnimatedMenuItemCard(item: item)),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cart.itemCount > 0 ? GoToCartFAB(canteen: widget.canteen) : null,
    );
  }
}


class GoToCartFAB extends StatelessWidget {
  final Canteen canteen;
  const GoToCartFAB({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CartScreen(canteen: canteen)),
        );
      },
      label: Text('VIEW CART (${cart.totalQuantity})'),
      icon: const Icon(Icons.shopping_cart_checkout),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.black,
    );
  }
}

class AnimatedMenuItemCard extends StatefulWidget {
  final MenuItemModel item;
  const AnimatedMenuItemCard({super.key, required this.item});

  @override
  State<AnimatedMenuItemCard> createState() => _AnimatedMenuItemCardState();
}

class _AnimatedMenuItemCardState extends State<AnimatedMenuItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: MenuItemCard(item: widget.item),
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 100,
            child: CachedNetworkImage(
              imageUrl: item.photoUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black12),
              errorWidget: (context, url, error) => Container(
                color: Colors.black12,
                child: Icon(Icons.fastfood, color: theme.colorScheme.primary, size: 40),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('₹${item.price}', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ),
          cartItem == null
              ? IconButton(
                  icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 30),
                  onPressed: () => cart.addItem(item),
                )
              : QuantityStepper(item: cartItem),
          const SizedBox(width: 8),
        ],
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
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.secondary), onPressed: () => cart.removeSingleItem(item.id)),
        Text(item.quantity.toString(), style: theme.textTheme.titleMedium),
        IconButton(icon: Icon(Icons.add_circle, color: theme.colorScheme.primary), onPressed: () => cart.addItem(MenuItemModel(id: item.id, name: item.name, price: item.price, category: item.category))),
      ],
    );
  }
}
