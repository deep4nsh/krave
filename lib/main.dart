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
import 'src/screens/user/user_home.dart';
import 'src/screens/owner/owner_home.dart';
import 'src/screens/owner/waiting_approval_screen.dart';
import 'src/screens/admin/admin_home.dart';

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
    // Define the professional color palette
    const primaryColor = Color(0xFF00E5FF); // Vibrant cyan/teal
    const backgroundColor = Color(0xFF0D1B2A); // Deep dark blue
    const surfaceColor = Color(0xFF1B263B); // Slightly lighter blue for cards
    const textColor = Color(0xFFE0E1DD); // Off-white for readability
    const secondaryTextColor = Color(0xFF778DA9); // Muted blue-grey

    final kraveTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: Colors.black, // Text on top of primary-colored elements (e.g., buttons)
        onBackground: textColor,
        onSurface: textColor,
        error: Colors.redAccent,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Make AppBar transparent to show body gradient
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryColor), // Style for back buttons, etc.
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primaryColor, width: 2), // Highlight when focused
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: primaryColor,
          foregroundColor: Colors.black, // Text color on the button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // FIXED: Use CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        elevation: 4,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceColor,
        contentTextStyle: TextStyle(color: textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor, height: 1.5),
        bodyMedium: TextStyle(color: secondaryTextColor, height: 1.5),
      ),
    );

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
        theme: kraveTheme, // Apply the new professional theme
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
