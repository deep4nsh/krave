import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/canteen_model.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/scale_button.dart';
import '../../widgets/skeleton_canteen_card.dart';
import '../../theme/app_colors.dart';
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
    // REMOVED clearCart() - Let users keep their progress if they navigate back/forth
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                title: Text(
                  widget.canteen.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.canteen.image ?? 'https://loremflickr.com/640/360/food?lock=${widget.canteen.id.hashCode}',
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.9)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<MenuItemModel>>(
              stream: fs.streamMenuItems(widget.canteen.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SkeletonMenuItem(),
                      childCount: 4,
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text('This canteen has no menu items yet.', style: TextStyle(color: AppColors.textLow))));
                }

                final groupedMenu = groupBy(items, (MenuItemModel item) => item.category ?? 'Other');

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
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
                              child: Text(category, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
                            ),
                            ...categoryItems.map((item) => MenuItemCard(item: item, canteen: widget.canteen)),
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

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final Canteen canteen;
  const MenuItemCard({super.key, required this.item, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItem = cart.items[item.id];
    final isAvailable = item.available;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      borderRadius: BorderRadius.circular(24),
      opacity: isAvailable ? 0.05 : 0.02,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _VegIcon(isVeg: item.isVeg),
                        if (item.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _TagBadge(tag: item.tags.first),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('₹${item.price}', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold, decoration: item.discountPrice != null ? TextDecoration.lineThrough : null)),
                        if (item.discountPrice != null) ...[
                          const SizedBox(width: 8),
                          Text('₹${item.discountPrice}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item.description ?? 'Chef\'s special ${item.name.toLowerCase()} prepared fresh.', style: TextStyle(color: AppColors.textLow, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: item.photoUrl ?? 'https://loremflickr.com/200/200/food?lock=${item.id.hashCode}',
                        height: 120, width: 120, fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      child: (isAvailable && canteen.isOpen) 
                        ? (cartItem == null ? _AddButton(onPressed: () {
                            HapticFeedback.lightImpact();
                            cart.addItem(item);
                          }) : _Stepper(item: cartItem, model: item))
                        : _UnavailableBadge(label: !canteen.isOpen ? 'CLOSED' : 'UNAVAILABLE'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}

class _VegIcon extends StatelessWidget {
  final bool isVeg;
  const _VegIcon({required this.isVeg});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5), borderRadius: BorderRadius.circular(4)), child: Icon(Icons.circle, size: 6, color: isVeg ? Colors.green : Colors.red));
}

class _TagBadge extends StatelessWidget {
  final String tag;
  const _TagBadge({required this.tag});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(tag.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)));
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) => ScaleButton(onPressed: onPressed, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]), child: const Text('ADD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))));
}

class _UnavailableBadge extends StatelessWidget {
  final String label;
  const _UnavailableBadge({this.label = 'UNAVAILABLE'});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)), child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 9)));
}

class _Stepper extends StatelessWidget {
  final CartItem item;
  final MenuItemModel model;
  const _Stepper({required this.item, required this.model});
  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16, color: Colors.black), 
            onPressed: () {
              HapticFeedback.lightImpact();
              cart.removeSingleItem(item.id);
            }, 
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
            padding: EdgeInsets.zero
          ),
          Text('${item.quantity}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: Colors.black), 
            onPressed: () {
              HapticFeedback.lightImpact();
              cart.addItem(model);
            }, 
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
            padding: EdgeInsets.zero
          ),
        ],
      ),
    );
  }
}

class FloatingCartBar extends StatelessWidget {
  final Canteen canteen;
  const FloatingCartBar({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ScaleButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(canteen: canteen))),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.primary,
          opacity: 0.9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('${cart.totalQuantity} ITEMS', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10)), Text('₹${cart.totalAmount}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))]),
              const Row(children: [Text('VIEW CART', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.shopping_bag_outlined, color: Colors.black)])
            ],
          ),
        ),
      ),
    );
  }
}
