import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_home.dart';
import '../auth/user_signup.dart';
import '../user/user_home.dart';
import '../owner/owner_home.dart';
import '../owner/waiting_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final cred = await auth.loginWithEmail(_email, _password);
      final role = await fs.getUserRole(cred.user!.uid);

      switch (role) {
        case 'admin':
          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const AdminHome()));
          break;
        case 'approvedOwner':
          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const OwnerHome()));
          break;
        case 'pendingOwner':
          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
          break;
        case 'user':
          navigator.pushReplacement(MaterialPageRoute(builder: (_) => const UserHome()));
          break;
        default:
          messenger.showSnackBar(const SnackBar(content: Text('No account found! Please register.')));
          await auth.logout(); // Log out the user as they have no valid role
      }

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
                onSaved: (v) => _email = v!,
              ),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: const Text('Login')),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSignupScreen())),
                    child: const Text('Register', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
