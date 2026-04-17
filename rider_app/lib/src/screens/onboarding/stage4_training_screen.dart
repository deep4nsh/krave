import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class Stage4TrainingScreen extends StatelessWidget {
  const Stage4TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Training'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learn the Basics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please complete the 3 short training modules to learn how the app works, how to deliver safely, and how to maximize your earnings.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              
              _buildTrainingCard('How orders work', Icons.delivery_dining),
              _buildTrainingCard('App Navigation', Icons.map_outlined),
              _buildTrainingCard('Safety & Conduct', Icons.health_and_safety_outlined),

              const Spacer(),
              
              ElevatedButton(
                onPressed: () async {
                  if (auth.rider == null) return;
                  await FirebaseService().updateOnboardingStep(auth.rider!.id, 5);
                  await auth.reloadRiderData();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Take the Quiz'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
