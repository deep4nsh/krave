import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../auth/user_signup.dart';

class OwnerSignupScreen extends StatefulWidget {
  const OwnerSignupScreen({Key? key}) : super(key: key);

  @override
  State<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

class _OwnerSignupScreenState extends State<OwnerSignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final canteenController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _signupOwner() async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('Owners').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'canteen_name': canteenController.text.trim(),
        'role': 'owner',
        'approved': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful! Waiting for admin approval.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Signup')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: canteenController, decoration: const InputDecoration(labelText: 'Canteen Name')),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signupOwner, child: const Text('Register Canteen')),

            const SizedBox(height: 20),

            // 👇 Link to Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // 👇 Link to User Signup
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSignupScreen()),
                );
              },
              child: const Text(
                'Register as User',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}