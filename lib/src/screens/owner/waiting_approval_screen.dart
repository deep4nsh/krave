import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'owner_home.dart';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 👇 Listen to the owner's Firestore document in real-time
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('Owners').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('No owner data found.')),
          );
        }

        final status = data['status'] ?? 'pending';

        // ✅ Auto-navigate to OwnerHome when approved
        if (status == 'approved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OwnerHome()),
            );
          });
        }

        // 🚫 Handle rejection too (optional)
        if (status == 'rejected') {
          return Scaffold(
            appBar: AppBar(title: const Text("Account Rejected")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel, size: 90, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text(
                      "Your account request has been rejected by the admin.\nPlease contact support for more information.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        auth.signOut().whenComplete(() {
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                          );
                        });
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ⏳ Default: still pending
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
                    auth.signOut().whenComplete(() {
                      if (!context.mounted) return;
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
      },
    );
  }
}