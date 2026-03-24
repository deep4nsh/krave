import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Start real-time listeners
    final orders = context.read<OrderProvider>();
    orders.listenActiveOrders();
    orders.listenAllOrders();
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Krave Rider',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (rider != null)
              Text(rider.name,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          // Online / Offline toggle
          if (_tab == 0 && rider != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Text(
                    rider.isActive ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: rider.isActive
                          ? AppTheme.accentGreen
                          : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: rider.isActive,
                    onChanged: (v) => auth.toggleActive(v),
                    activeTrackColor: AppTheme.accentGreen,
                    inactiveThumbColor: AppTheme.textMuted,
                    inactiveTrackColor: AppTheme.surfaceVariant,
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
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.bolt_rounded), label: 'Live Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
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

    if (!rider!.isActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.power_settings_new_rounded,
                  size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            const Text('You\'re Offline',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Toggle the switch above to go online\nand start receiving orders.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final activeOrders = orders.activeOrders;

    if (activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 40, color: AppTheme.accentGreen),
            ),
            const SizedBox(height: 20),
            const Text('All Clear!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('No active orders right now.\nNew orders will appear here instantly.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentGreen.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  color: AppTheme.accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                '${activeOrders.length} active order${activeOrders.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: activeOrders.length,
            itemBuilder: (ctx, i) {
              final o = activeOrders[i];
              return OrderCard(
                order: o,
                canteenName: orders.canteenName(o.canteenId),
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: o.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
