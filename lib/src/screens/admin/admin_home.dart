import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'owner_approval_screen.dart';
import 'manage_canteens.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textMed)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textHigh)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white24, size: 22),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(20.0),
          borderRadius: BorderRadius.circular(24),
          opacity: 0.05,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textLow)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
