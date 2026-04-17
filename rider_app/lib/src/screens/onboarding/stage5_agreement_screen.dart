import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class Stage5AgreementScreen extends StatefulWidget {
  const Stage5AgreementScreen({super.key});

  @override
  State<Stage5AgreementScreen> createState() => _Stage5AgreementScreenState();
}

class _Stage5AgreementScreenState extends State<Stage5AgreementScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.5),
                border: const Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: List.generate(6, (index) {
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index <= 4 ? AppTheme.primary : AppTheme.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('STEP 05/06',
                          style: GoogleFonts.outfit(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5)),
                      Text('RIDER AGREEMENT',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'The Fine Print',
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                  ).animate().fadeIn().slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  Text(
                    'Almost there! Please review and accept the rider guidelines to activate your account.',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 15),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildClause(Icons.health_and_safety_rounded, 'Safety First', 'Deliver food safely and strictly follow campus traffic rules.'),
                        _buildClause(Icons.stars_rounded, 'Professionalism', 'Maintain a professional and friendly attitude with all Krave users.'),
                        _buildClause(Icons.payments_rounded, 'Weekly Earnings', 'All earnings will be credited weekly to your linked bank account.'),
                        _buildClause(Icons.verified_user_rounded, 'Account Policy', 'Krave reserves the right to suspend accounts for policy violations.'),
                        _buildClause(Icons.commute_rounded, 'Vehicle Check', 'You are responsible for the legality and maintenance of your vehicle.'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
                  
                  const SizedBox(height: 24),
                  
                  // Big Checkbox Card
                  InkWell(
                    onTap: () => setState(() => _accepted = !_accepted),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _accepted ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accepted ? AppTheme.primary : AppTheme.border, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _accepted ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _accepted ? AppTheme.primary : AppTheme.textMuted, width: 2),
                            ),
                            child: _accepted ? const Icon(Icons.check, size: 20, color: Colors.black) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'I have read and I accept the terms of the Krave Rider Agreement.',
                              style: GoogleFonts.outfit(
                                fontSize: 14, 
                                fontWeight: _accepted ? FontWeight.bold : FontWeight.normal,
                                color: _accepted ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _accepted
                    ? () async {
                        if (auth.rider == null) return;
                        await FirebaseService().updateOnboardingStep(auth.rider!.id, 6);
                        await auth.reloadRiderData();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('ACCEPT & CONTINUE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ).animate().slideY(begin: 0.2).fadeIn(delay: 500.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClause(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
