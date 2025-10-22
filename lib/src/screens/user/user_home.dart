// lib/screens/user/user_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Add this
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import 'canteen_menu.dart';
import '../auth/login_screen.dart'; // 👈 Import your login screen

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  // 🔹 Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      // Navigate to Login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krave - Canteens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Canteen>>(
        stream: fs.streamApprovedCanteens(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No approved canteens.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text('Owner: ${c.ownerId}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CanteenMenu(canteen: c)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}