// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../owner/waiting_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  String name = '', email = '', password = '', role = 'user';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Register - Krave')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => name = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => email = v?.trim() ?? '',
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => password = v ?? '',
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'user'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  _form.currentState!.save();
                  setState(() => loading = true);

                  try {
                    // 1) Create Firebase Auth user
                    final cred = await auth.registerWithEmail(email, password);

                    // 2) Create Users doc (profile)
                    final uid = cred.user!.uid;
                    final userModel = KraveUser(
                      id: uid,
                      name: name,
                      email: email,
                      role: role,
                      approved: role == 'user', // users auto-approved
                    );
                    await fs.createUser(userModel);

                    // 3) If role == owner -> create Owners/{uid} with approved:false
                    if (role == 'owner') {
                      await fs.addOwner(uid, name, email);
                      // Option A: Immediately sign out and show waiting screen:
                      // await auth.logout(); // optional: sign out so they must login again
                      // Navigate to WaitingApproval screen (owners must wait)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()),
                      );
                      return;
                    }

                    // Non-owner flow: navigate to login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    setState(() => loading = false);
                  }
                },
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Already have account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}