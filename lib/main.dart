import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/services/image_search_service.dart';
import 'src/services/notification_service.dart';
import 'src/services/cart_provider.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/auth/phone_verification_screen.dart';
import 'src/screens/user/user_home.dart';
import 'src/screens/owner/owner_home.dart';
import 'src/screens/owner/waiting_approval_screen.dart';
import 'src/screens/admin/admin_home.dart';
import 'src/services/user_provider.dart';
import 'src/services/watchdog_service.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  await NotificationService().init();
  await ImageSearchService.loadApiKeys();

  runApp(const KraveApp());
}

class KraveApp extends StatelessWidget {
  const KraveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        Provider<ImageSearchService>(create: (_) => ImageSearchService()),
      ],
      child: MaterialApp(
        title: 'Krave',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const Root(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/user_home': (_) => const UserHome(),
          '/admin_home': (_) => const AdminHome(),
        },
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // Bridge to UserProvider for profile and role management
        return Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            // Trigger session initialization if needed
            if (userProvider.status == SessionStatus.initial || 
                (userProvider.user == null && !userProvider.isLoading && userProvider.status != SessionStatus.error)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                userProvider.initializeSession(firebaseUser.uid);
              });
            }

            switch (userProvider.status) {
              case SessionStatus.initial:
              case SessionStatus.fetchingProfile:
              case SessionStatus.authenticating:
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              
              case SessionStatus.admin:
                return const AdminHome();
              
              case SessionStatus.pendingOwner:
                return const WaitingApprovalScreen();
              
              case SessionStatus.authenticated:
                final profile = userProvider.user;
                if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                
                // Logic side-effects (e.g., Master Watchdog)
                WatchdogService().start(profile.id);

                if (profile.role == 'approvedOwner') {
                  return const OwnerHome();
                }

                if (profile.phone == null || profile.phone!.isEmpty) {
                  return const PhoneVerificationScreen();
                }
                
                return const UserHome();

              case SessionStatus.error:
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text('Session Error', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(userProvider.errorMessage ?? 'Unknown error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => userProvider.initializeSession(firebaseUser.uid),
                            child: const Text('Retry Connection'),
                          ),
                          TextButton(onPressed: () => auth.logout(), child: const Text('Sign Out')),
                        ],
                      ),
                    ),
                  ),
                );
              
              case SessionStatus.unauthenticated:
                return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
