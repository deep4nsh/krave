import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import '../auth/login_screen.dart';
import 'owner_approval_screen.dart';
import 'manage_canteens.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            _AnimatedAdminTaskCard(
              title: 'Owner Approvals',
              subtitle: 'Approve or reject new canteen owners.',
              icon: Icons.how_to_reg,
              route: OwnerApprovalScreen(),
            ),
            SizedBox(height: 16),
            _AnimatedAdminTaskCard(
              title: 'Manage Canteens',
              subtitle: 'View and revoke approved canteens.',
              icon: Icons.store,
              route: ManageCanteensScreen(),
            ),
            // Add other admin tasks here as needed
          ],
        ),
      ),
    );
  }
}

class _AnimatedAdminTaskCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget route;

  const _AnimatedAdminTaskCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  @override
  State<_AnimatedAdminTaskCard> createState() => _AnimatedAdminTaskCardState();
}

class _AnimatedAdminTaskCardState extends State<_AnimatedAdminTaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
        child: _AdminTaskCard(
          title: widget.title,
          subtitle: widget.subtitle,
          icon: widget.icon,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => widget.route)),
        ),
      ),
    );
  }
}

class _AdminTaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminTaskCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(icon, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.secondary, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
