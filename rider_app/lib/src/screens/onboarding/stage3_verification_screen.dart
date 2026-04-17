import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class Stage3VerificationScreen extends StatelessWidget {
  const Stage3VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification in Progress',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Our team is reviewing your documents. This usually takes between 2 to 24 hours. You will be notified once complete.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // MOCK DEV BUTTON: Auto verify
              ElevatedButton(
                onPressed: () async {
                  if (auth.rider == null) return;
                  // Dev tool to bypass manual verification
                  final svc = FirebaseService();
                  await svc.updateOnboardingStep(auth.rider!.id, 4);
                  // AuthProvider will pick up the change via listener or manual reload
                  // For now, we manually reload rider data:
                  await auth.reloadRiderData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                child: const Text('DEV: Mock Verification Success'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
