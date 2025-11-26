import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../models/canteen_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/scale_button.dart';
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
      extendBodyBehindAppBar: true, 
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 150.0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.canteen.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            StreamBuilder<List<MenuItemModel>>(
              stream: fs.streamMenuItems(widget.canteen.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('An error occurred: ${snap.error}')),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('This canteen has no menu items yet.')),
                  );
                }

                final groupedMenu = groupBy(items, (MenuItemModel item) => item.category ?? 'Other');

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100), // Padding for FAB
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                      childCount: groupedMenu.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cart.items.isEmpty ? null : FloatingCartBar(canteen: widget.canteen),
    );
  }
}

class FloatingCartBar extends StatelessWidget {
  final Canteen canteen;
  const FloatingCartBar({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 60,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary,
        opacity: 0.9,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen(canteen: canteen)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.totalQuantity} ITEMS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₹${cart.totalAmount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: const [
                    Text(
                      'View Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Veg/Non-veg Icon
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: item.isVeg ? Colors.green : Colors.red, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: item.isVeg ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price}',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delicious ${item.category?.toLowerCase() ?? 'item'} prepared with care.', // Placeholder description
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Right Side: Image and Add Button
          SizedBox(
            width: 120,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: CachedNetworkImage(
                      imageUrl: item.photoUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white10,
                        child: Icon(Icons.fastfood, color: theme.colorScheme.primary.withOpacity(0.5), size: 40),
                      ),
                    ),
                  ),
                ),
                
                // Add Button (Pill)
                Positioned(
                  bottom: -12,
                  child: cartItem == null
                      ? ScaleButton(
                          onPressed: () => cart.addItem(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'ADD',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : QuantityStepper(item: cartItem),
                ),
              ],
            ),
          ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleButton(
            onPressed: () => cart.removeSingleItem(item.id),
            child: Icon(Icons.remove, color: theme.colorScheme.primary, size: 20),
          ),
          SizedBox(
            width: 30,
            child: Text(
              item.quantity.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ScaleButton(
            onPressed: () => cart.addItem(MenuItemModel(id: item.id, name: item.name, price: item.price, category: item.category)),
            child: Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
          ),
        ],
      ),
    );
  }
}
