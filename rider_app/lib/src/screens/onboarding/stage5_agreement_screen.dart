import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        title: const Text('Agreement & T&C'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms and Conditions',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        '1. You agree to deliver food safely and on time.\n\n'
                        '2. You will maintain a professional attitude with customers and restaurant partners.\n\n'
                        '3. Payments will be credited weekly directly to your linked bank account.\n\n'
                        '4. Krave reserves the right to terminate your account in case of continuous policy violation or severe infractions.\n\n'
                        '5. You are responsible for the compliance of your vehicle with local traffic laws.',
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Checkbox(
                          value: _accepted,
                          onChanged: (val) {
                            setState(() => _accepted = val ?? false);
                          },
                          activeColor: AppTheme.accent,
                        ),
                        const Expanded(
                          child: Text(
                            'I accept the terms and conditions and agree to abide by the rider guidelines.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Accept and Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
