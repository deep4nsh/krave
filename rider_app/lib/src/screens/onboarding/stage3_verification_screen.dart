import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class Stage3VerificationScreen extends StatelessWidget {
  const Stage3VerificationScreen({super.key});

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
                            color: index <= 2 ? AppTheme.primary : AppTheme.border,
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
                      Text('STEP 03/06',
                          style: GoogleFonts.outfit(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5)),
                      Text('VERIFICATION',
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.05),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.radar_rounded,
                          size: 60,
                          color: AppTheme.primary,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: AppTheme.primary.withOpacity(0.2)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
                    const SizedBox(height: 48),
                    Text(
                      'Hold tight, Partner!',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                    Text(
                      'Our team is reviewing your documents to ensure everything is in order. This usually takes 2-24 hours.',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16, height: 1.5),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 48),
                    
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
                          Text('WHAT HAPPENS NEXT?', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          _buildStep('01', 'Document approval notification'),
                          _buildStep('02', 'Access to Rider Training modules'),
                          _buildStep('03', 'Account activation & First delivery!'),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    
                    const Spacer(),
                    
                    // MOCK DEV BUTTON: Auto verify (Restyled)
                    TextButton(
                      onPressed: () async {
                        if (auth.rider == null) return;
                        final svc = FirebaseService();
                        await svc.updateOnboardingStep(auth.rider!.id, 4);
                        await auth.reloadRiderData();
                      },
                      child: Text('REFRESH STATUS', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String num, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(num, style: GoogleFonts.outfit(color: AppTheme.textMuted, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(width: 16),
          Expanded(child: Text(desc, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }
}
