// lib/screens/owner/waiting_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class WaitingApprovalScreen extends StatelessWidget {
  const WaitingApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return Scaffold(
      appBar: AppBar(title: const Text("Waiting for Approval")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.hourglass_empty, size: 90, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Thanks for signing up as a canteen owner.\nYour account is pending admin approval.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Optional: sign out user and go to login
                auth.signOut().whenComplete(() {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                });
              },
              child: const Text('Logout'),
            ),
          ]),
        ),
      ),
    );
  }
}