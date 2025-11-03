import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import '../../widgets/gradient_background.dart';
import 'canteen_menu.dart';
import '../auth/login_screen.dart';
import 'order_history.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krave'),
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
      body: GradientBackground(
        child: StreamBuilder<List<Canteen>>(
          stream: fs.streamApprovedCanteens(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final canteens = snap.data ?? [];
            if (canteens.isEmpty) {
              return const Center(child: Text('No approved canteens available right now.'));
            }
            // Use ListView.separated for better spacing and animations
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: canteens.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                // Wrap card in an animation widget
                return _AnimatedCanteenCard(canteen: canteens[i], index: i);
              },
            );
          },
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
        child: CanteenCard(canteen: widget.canteen),
      ),
    );
  }
}

class CanteenCard extends StatelessWidget {
  final Canteen canteen;
  const CanteenCard({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTimings = canteen.openingTime != null && canteen.closingTime != null;

    return Card(
      // The new CardTheme from main.dart is applied automatically
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CanteenMenu(canteen: canteen)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(canteen.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  if (hasTimings)
                    Text('${canteen.openingTime} - ${canteen.closingTime}', style: theme.textTheme.bodyMedium)
                  else
                    Text('Timings not available', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
