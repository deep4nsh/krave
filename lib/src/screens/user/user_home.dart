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
import '../../widgets/skeleton_canteen_card.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/restaurant_card.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

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
      if (context.mounted) {
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
              floating: true,
              snap: true,
              title: Text('Krave', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_edu),
                  tooltip: 'Order History',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  tooltip: 'Logout',
                  onPressed: () => _logout(context),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(12),
                  opacity: 0.1,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for food or restaurants...',
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
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
                final canteens = snap.data ?? [];
                if (canteens.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No approved canteens available right now.')),
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


