import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'src/screens/user/user_home.dart';
import 'src/screens/owner/owner_home.dart';
import 'src/screens/owner/waiting_approval_screen.dart';
import 'src/screens/admin/admin_home.dart';
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
