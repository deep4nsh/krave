 import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import '../../widgets/gradient_background.dart';
import 'canteen_menu.dart';
import '../auth/login_screen.dart';
import 'order_history.dart';
import 'profile_screen.dart';
import '../../widgets/skeleton_canteen_card.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/developer_note_dialog.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String _searchQuery = '';

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthService>();
    try {
      await auth.logout();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final theme = Theme.of(context);

    return Scaffold(
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Krave',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                background: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: GlassContainer(
                    padding: const EdgeInsets.all(8),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.history_rounded, size: 20),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                ),
                IconButton(
                  icon: GlassContainer(
                    padding: const EdgeInsets.all(8),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      "What's on your mind?",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Hero(
                      tag: 'search_bar',
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        opacity: 0.08,
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search for food or restaurants...',
                            prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                            suffixIcon: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                          ),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ),
                  // Categories Row
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _CategoryItem(label: 'All', icon: Icons.restaurant_rounded, isSelected: _searchQuery.isEmpty),
                        _CategoryItem(label: 'Burger', icon: Icons.lunch_dining_rounded),
                        _CategoryItem(label: 'Pizza', icon: Icons.local_pizza_rounded),
                        _CategoryItem(label: 'Coffee', icon: Icons.coffee_rounded),
                        _CategoryItem(label: 'Desert', icon: Icons.icecream_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Popular Canteens",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            StreamBuilder<List<Canteen>>(
              stream: fs.streamApprovedCanteens(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const SkeletonCanteenCard(),
                        childCount: 5,
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snap.error}')),
                  );
                }
                
                final allCanteens = snap.data ?? [];
                final canteens = allCanteens.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (canteens.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No canteens found.')),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final canteen = canteens[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _AnimatedCanteenCard(canteen: canteen, index: index),
                        );
                      },
                      childCount: canteens.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCanteenCard extends StatefulWidget {
  final Canteen canteen;
  final int index;

  const _AnimatedCanteenCard({required this.canteen, required this.index});

  @override
  State<_AnimatedCanteenCard> createState() => _AnimatedCanteenCardState();
}

class _AnimatedCanteenCardState extends State<_AnimatedCanteenCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Stagger the animation based on the item's index
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RestaurantCard(canteen: widget.canteen),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _CategoryItem({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(16),
            opacity: isSelected ? 0.9 : 0.05,
            color: isSelected ? theme.colorScheme.primary : Colors.white,
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? theme.colorScheme.primary : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}


