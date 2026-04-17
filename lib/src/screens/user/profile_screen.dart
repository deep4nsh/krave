import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/user_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'transfer_money_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textHigh)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
          child: Column(
            children: [
              _buildProfileHeader(context, user?.email ?? 'User'),
              const SizedBox(height: 32),
              
              // Krave Wallet Dashboard
              _buildWalletCard(context, userProvider),
              const SizedBox(height: 32),
              
              _buildProfileOption(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Account Settings',
                subtitle: 'Manage your profile and security',
              ),
              _buildProfileOption(
                context,
                icon: Icons.history_rounded,
                title: 'Order Settings',
                subtitle: 'History, tax invoices, and refunds',
              ),
              _buildProfileOption(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get assistance and FAQs',
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, UserProvider provider) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KRAVE WALLET', style: GoogleFonts.outfit(color: AppColors.primary, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('₹${provider.balance.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferMoneyScreen())),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Money', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  opacity: 0.05,
                  child: TextButton(
                    onPressed: () => provider.topUpWallet(500),
                    child: const Text('Top-up ₹500', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildProfileHeader(BuildContext context, String email) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.5)]),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20)],
          ),
          child: const Icon(Icons.person_rounded, size: 40, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Text(email.split('@')[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        opacity: 0.05,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHigh)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white30)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white12),
          ],
        ),
      ),
    );
  }
}
