import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class Stage6SuccessScreen extends StatelessWidget {
  const Stage6SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt_rounded, // or Icons.stars_rounded
                    color: AppTheme.primary,
                    size: 80,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).shimmer(delay: 800.ms, duration: 2.seconds),
              const SizedBox(height: 48),
              Text(
                'You\'re Activated!',
                style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, height: 1.1),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              const Text(
                'Welcome to the elite fleet. Your account is ready and you can start delivering right away.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 40, spreadRadius: 5)
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('RIDER ID', auth.rider?.id.substring(0, 6).toUpperCase() ?? 'KRAVE'),
                    Container(height: 32, width: 1, color: AppTheme.border),
                    _buildStatCol('FLEET', 'ALPHA'),
                    Container(height: 32, width: 1, color: AppTheme.border),
                    _buildStatCol('CITY', auth.rider?.city.toUpperCase() ?? 'KRAVE'),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: () async {
                  if (auth.rider == null) return;
                  await FirebaseService().updateOnboardingStep(auth.rider!.id, 7);
                  await auth.reloadRiderData();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: AppTheme.primary,
                  elevation: 12,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                ),
                child: Text('GO ONLINE NOW', 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.black)),
              ).animate().slideY(begin: 0.2).fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String title, String value) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
