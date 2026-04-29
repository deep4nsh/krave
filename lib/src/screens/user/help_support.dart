import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Frequently Asked Questions'),
              const SizedBox(height: 16),
              _buildFAQTile(
                'How do I top up my wallet?',
                'Go to your Profile, tap on "Top-up" in the Wallet card, and select the amount. You can pay via UPI, Card, or Netbanking.',
              ),
              _buildFAQTile(
                'Can I cancel an order?',
                'Orders can be cancelled as long as they are in "Pending" status. Once the canteen starts "Preparing" your food, cancellation depends on their policy.',
              ),
              _buildFAQTile(
                'How does delivery work?',
                'Krave partners with student riders. Select "Delivery" at checkout, and a rider will pick up your order and deliver it to your specified hostel location.',
              ),
              _buildFAQTile(
                'What if my payment fails?',
                'If money is deducted but the order isn\'t placed, it usually refunds automatically within 3-5 business days. Contact support if it persists.',
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Contact Us'),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                icon: Icons.email_rounded,
                title: 'Email Support',
                subtitle: 'support@krave.com',
                onTap: () => _launchEmail('support@krave.com'),
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                icon: Icons.phone_rounded,
                title: 'Phone Support',
                subtitle: '+91 99999 00000',
                onTap: () => _launchPhone('+919999900000'),
              ),
              
              const SizedBox(height: 48),
              Center(
                child: Opacity(
                  opacity: 0.3,
                  child: Column(
                    children: [
                      const Text('Krave v1.0.0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Made with ❤️ for Students', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        opacity: 0.05,
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              question,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textLow,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                answer,
                style: const TextStyle(color: AppColors.textMed, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        opacity: 0.1,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textLow, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Krave Support Request',
    );
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri params = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }
}
