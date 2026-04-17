import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class Stage4TrainingScreen extends StatelessWidget {
  const Stage4TrainingScreen({super.key});

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
                            color: index <= 3 ? AppTheme.primary : AppTheme.border,
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
                      Text('STEP 04/06',
                          style: GoogleFonts.outfit(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5)),
                      Text('RIDER TRAINING',
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
                    'Level Up Your Skills',
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                  ).animate().fadeIn().slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  Text(
                    'Complete these quick modules to master the Krave app and boost your ratings.',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 15),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  
                  _buildTrainingCard(
                    'How Orders Work', 
                    'Learn the lifecycle from kitchen to student.',
                    Icons.delivery_dining_rounded,
                    '4 MIN'
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  
                  _buildTrainingCard(
                    'App Navigation', 
                    'Master the active tasks and earnings feed.',
                    Icons.explore_rounded,
                    '3 MIN'
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  
                  _buildTrainingCard(
                    'Safety & Conduct', 
                    'Protocol for campus deliveries and hygiene.',
                    Icons.health_and_safety_rounded,
                    '5 MIN'
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (auth.rider == null) return;
                  await FirebaseService().updateOnboardingStep(auth.rider!.id, 5);
                  await auth.reloadRiderData();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('TAKE THE QUIZ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ).animate().slideY(begin: 0.2).fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCard(String title, String subtitle, IconData icon, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () {}, // For future detail pages
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(time, style: GoogleFonts.outfit(color: AppTheme.textMuted, fontWeight: FontWeight.w900, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
