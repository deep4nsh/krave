// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';

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
    final auth = Provider.of<AuthService>(context);
    final fs = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Register - Krave')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading ? const Center(child: CircularProgressIndicator()) : Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Name'), onSaved: (v) => name = v ?? ''),
              TextFormField(decoration: const InputDecoration(labelText: 'Email'), onSaved: (v) => email = v ?? ''),
              TextFormField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true, onSaved: (v) => password = v ?? ''),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                ],
                onChanged: (v) => setState(() { role = v ?? 'user'; }),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () async {
                _form.currentState!.save();
                setState(() { loading = true; });
                try {
                  final cred = await auth.registerWithEmail(email, password);
                  final u = KraveUser(id: cred.user!.uid, name: name, email: email, role: role, approved: role == 'user');
                  await fs.createUser(u);
                  // Show message: registered
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  setState(() { loading = false; });
                }
              }, child: const Text('Register')),
            ],
          ),
        ),
      ),
    );
  }
}