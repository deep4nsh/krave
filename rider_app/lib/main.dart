import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'src/services/firebase_service.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/order_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/theme/app_theme.dart';
import 'firebase_options.dart';

import 'package:krave/src/constants/app_constants.dart';

import 'src/screens/onboarding/stage1_basic_profile_screen.dart';
import 'src/screens/onboarding/stage2_kyc_screen.dart';
import 'src/screens/onboarding/stage3_verification_screen.dart';
import 'src/screens/onboarding/stage4_training_screen.dart';
import 'src/screens/onboarding/stage5_agreement_screen.dart';
import 'src/screens/onboarding/stage6_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KraveRiderApp());
}

class KraveRiderApp extends StatelessWidget {
  const KraveRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => OrderProvider(firebaseService)),
      ],
      child: MaterialApp(
        title: 'Krave Rider',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Switches between Auth, Onboarding, and Home based on auth state and rider status
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.state) {
      case AuthState.initial:
      case AuthState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthState.otpSent:
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
      case AuthState.authenticated:
        final rider = auth.rider;
        if (rider == null) return const Scaffold(body: Center(child: Text('Loading Rider...')));

        if (rider.status == RiderStatus.onboarding || rider.status == RiderStatus.pendingApproval) {
          switch (rider.onboardingStep) {
            case 1:
              return const Stage1BasicProfileScreen();
            case 2:
              return const Stage2KycScreen();
            case 3:
              return const Stage3VerificationScreen();
            case 4:
              return const Stage4TrainingScreen();
            case 5:
              return const Stage5AgreementScreen();
            case 6:
              return const Stage6SuccessScreen();
            default:
              return const Stage1BasicProfileScreen();
          }
        }
        
        return const HomeScreen();
    }
  }
}
