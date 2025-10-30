// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart';
import 'src/services/notification_service.dart';
import 'src/services/cart_provider.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/user/user_home.dart';
import 'src/screens/owner/owner_home.dart';
import 'src/screens/owner/waiting_approval_screen.dart';
import 'src/screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init();

  runApp(const KraveApp());
}

class KraveApp extends StatelessWidget {
  const KraveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepOrange);
    return MultiProvider(
      providers: [
        // App-wide services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Krave',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            centerTitle: true,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: const StadiumBorder(),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.primary,
            contentTextStyle: TextStyle(color: colorScheme.onPrimary),
          ),
        ),
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
    final auth = context.watch<AuthService>();

    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return FutureBuilder<String>(
            future: context.read<FirestoreService>().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              switch (roleSnapshot.data) {
                case 'admin':
                  return const AdminHome();
                case 'approvedOwner':
                  return const OwnerHome();
                case 'pendingOwner':
                  return const WaitingApprovalScreen();
                case 'user':
                  return const UserHome();
                default:
                  return const LoginScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
