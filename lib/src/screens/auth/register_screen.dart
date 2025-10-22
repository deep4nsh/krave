// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../owner/waiting_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  String name = '', email = '', password = '', role = 'user', canteenName = '';
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
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => email = v?.trim() ?? '',
                validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter valid email' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => password = v ?? '',
                validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'user'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),

              // 👇 Only show this if owner is selected
              if (role == 'owner') ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Canteen Name'),
                  onSaved: (v) => canteenName = v?.trim() ?? '',
                  validator: (v) => (role == 'owner' &&
                      (v == null || v.trim().isEmpty))
                      ? 'Enter canteen name'
                      : null,
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  _form.currentState!.save();
                  setState(() => loading = true);

                  try {
                    // Step 1: Create Firebase Auth user
                    final cred = await auth.registerWithEmail(email, password);
                    final uid = cred.user!.uid;

                    // Step 2: Create User document
                    final user = KraveUser(
                      id: uid,
                      name: name,
                      email: email,
                      role: role,
                      approved: role == 'user', // users auto-approved
                    );
                    await fs.createUser(user);

                    // Step 3: Handle owner-specific logic
                    if (role == 'owner') {
                      await fs.addOwner(uid, name, email, canteenName);
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WaitingApprovalScreen(),
                        ),
                      );
                      return;
                    }

                    // Step 4: Normal user → Go to login
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}