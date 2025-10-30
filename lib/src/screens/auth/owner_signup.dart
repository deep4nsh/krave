import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../auth/user_signup.dart';
import '../owner/waiting_approval_screen.dart';

class OwnerSignupScreen extends StatefulWidget {
  const OwnerSignupScreen({super.key});

  @override
  State<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

class _OwnerSignupScreenState extends State<OwnerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '', _email = '', _password = '', _canteenName = '';
  bool _loading = false;

  Future<void> _signupOwner() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final cred = await auth.registerWithEmail(_email, _password);
      await fs.addOwner(cred.user!.uid, _name, _email, _canteenName);

      messenger.showSnackBar(const SnackBar(content: Text('Signup successful! Waiting for admin approval.')));
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Signup')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                onSaved: (v) => _name = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
                onSaved: (v) => _email = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Canteen Name'),
                validator: (v) => v!.isEmpty ? 'Please enter the canteen name' : null,
                onSaved: (v) => _canteenName = v!,
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _signupOwner, child: const Text('Register Canteen')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Login', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserSignupScreen())),
                child: const Text('Register as User', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
