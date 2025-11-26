import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_background.dart'; // Import the new background
import '../admin/admin_home.dart';
import '../auth/user_signup.dart';
import '../user/user_home.dart';
import '../owner/owner_home.dart';
import '../owner/waiting_approval_screen.dart';
import '../../widgets/scale_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Add SingleTickerProviderStateMixin for animations
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';
  bool _loading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final cred = await auth.loginWithEmail(_email, _password);
      final role = await fs.getUserRole(cred.user!.uid);

      // Navigate based on role
      final pageRoute = switch (role) {
        'admin' => MaterialPageRoute(builder: (_) => const AdminHome()),
        'approvedOwner' => MaterialPageRoute(builder: (_) => const OwnerHome()),
        'pendingOwner' => MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()),
        'user' => MaterialPageRoute(builder: (_) => const UserHome()),
        _ => null,
      };

      if (pageRoute != null) {
        navigator.pushReplacement(pageRoute);
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('No account found! Please register.')));
        await auth.logout();
      }
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().split('] ').last)));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Title
                    Icon(Icons.fastfood, size: 60, color: colorScheme.primary), // FIXED: Get color from theme
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Krave',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // Animated Form
                    SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
                              onSaved: (v) => _email = v!,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Password'),
                              validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                              onSaved: (v) => _password = v!,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ScaleButton(
                            onPressed: _login,
                            child: Container(
                              height: 52,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Login',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // Registration Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSignupScreen())),
                          child: Text(
                            'Register',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
