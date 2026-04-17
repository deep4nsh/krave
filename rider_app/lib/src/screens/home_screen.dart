import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final orders = context.read<OrderProvider>();
    orders.listenActiveOrders();
    orders.listenAllOrders();
    _startLocationSimulation();
  }

  void _startLocationSimulation() async {
    // In a real app, this would use Geolocator.getPositionStream()
    // For this build, we simulate movement to update the new currentLocation field
    while (mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.rider != null && auth.rider!.isActive) {
        // Simulate minor movement
        final lat = 28.7041 + (0.001 * (0.5 - (DateTime.now().second % 10) / 10));
        final lng = 77.1025 + (0.001 * (0.5 - (DateTime.now().second % 10) / 10));
        
        await context.read<FirebaseService>().updateRiderLocation(
          auth.rider!.id, 
          lat, 
          lng
        );
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rider = auth.rider;

    final pages = [
      const _LiveFeedPage(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Krave Rider',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            if (rider != null)
              Text(rider.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
          ],
        ),
        actions: [
          if (_tab == 0 && rider != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    rider.isActive ? 'ONLINE' : 'OFFLINE',
                    style: GoogleFonts.outfit(
                      color: rider.isActive ? AppTheme.primary : AppColors.textLow,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: rider.isActive,
                    onChanged: (v) => auth.toggleActive(v),
                    activeColor: AppTheme.primary,
                    activeTrackColor: AppTheme.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: AppTheme.background,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Me'),
          ],
        ),
      ),
    );
  }
}

class _LiveFeedPage extends StatelessWidget {
  const _LiveFeedPage();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final rider = auth.rider;

    if (rider == null) return const SizedBox.shrink();

    if (!rider.isActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.power_settings_new_rounded, size: 40, color: AppColors.textLow),
            ).animate().shake(delay: 500.ms),
            const SizedBox(height: 24),
            Text('You\'re Currently Offline',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Go online to start receiving\ndelivery requests.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ).animate().fadeIn();
    }

    final activeOrders = orders.activeOrders;

    if (activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: const Icon(Icons.celebration_rounded, size: 40, color: AppTheme.primary),
            ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('The Deck is Clear!',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('New delivery orders will appear\nhere automatically.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ).animate().fadeIn();
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 12),
              Text(
                '${activeOrders.length} DELIVERY TASK${activeOrders.length > 1 ? 'S' : ''} ACTIVE',
                style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1),
              ),
            ],
          ),
        ).animate().slideX(begin: -0.1).fadeIn(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: activeOrders.length,
            itemBuilder: (ctx, i) {
              final o = activeOrders[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OrderCard(
                  order: o,
                  canteenName: orders.canteenName(o.canteenId),
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: o.id),
                    ),
                  ),
                ).animate().slideY(begin: 0.2, delay: (100 * i).ms).fadeIn(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Minimal local color helper to avoid cyclic dependency if AppColors was moved
class AppColors {
  static const Color textLow = Color(0xFF64748B);
}
