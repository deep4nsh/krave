// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../user/user_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  String email = '', password = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final fs = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Login - Krave')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading ? const Center(child: CircularProgressIndicator()) : Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Email'), onSaved: (v) => email = v ?? ''),
              TextFormField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true, onSaved: (v) => password = v ?? ''),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () async {
                _form.currentState!.save();
                setState(() { loading = true; });
                try {
                  await auth.loginWithEmail(email, password);
                  final user = auth.currentUser!;
                  final uModel = await fs.getUser(user.uid);
                  if (uModel == null) {
                    // no profile
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile missing')));
                    return;
                  }
                  if (uModel.role == 'user') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserHome()));
                  }
                  else if (uModel.role == 'owner') {
                    bool approved = await FirestoreService().isOwnerApproved(user.uid);
                    if (approved) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerHome()));
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
                    }
                  }
                  else {
                    // TODO owner/admin screens
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserHome()));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  setState(() { loading = false; });
                }
              }, child: const Text('Login')),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Register'))
            ],
          ),
        ),
      ),
    );
  }
}