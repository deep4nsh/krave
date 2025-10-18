import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:krave/src/screens/admin/admin_home.dart';
import 'package:krave/src/screens/auth/user_signup.dart';
import '../user/user_home.dart';
import '../owner/owner_home.dart';
import '../owner/waiting_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String adminEmail = 'kraveadmin@secret.com';
  static const String adminPassword = 'Krave123!';
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email == adminEmail && password == adminPassword) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminHome()));
      return;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      final ownerDoc = await FirebaseFirestore.instance.collection('Owners').doc(uid).get();

      if (!mounted) return;

      if (userDoc.exists) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserHome()));
      } else if (ownerDoc.exists) {
        final approved = ownerDoc['approved'] ?? false;
        if (approved) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerHome()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found! Please register.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),

            const SizedBox(height: 15),

            // 👇 New “Register” navigation text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserSignupScreen()), // 👈 Navigate to registration
                    );
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}