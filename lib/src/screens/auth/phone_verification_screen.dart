import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/krave_button.dart';
import '../../widgets/krave_textfield.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  Future<void> _sendOTP() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid phone number')));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    setState(() {
      _otpSent = true;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock OTP "123456" sent!')));
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP! (Try 123456)')));
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final userProvider = context.read<UserProvider>();

    try {
      final user = auth.currentUser;
      if (user != null) {
        // Update user profile with phone number
        await fs.updateUserPhone(user.uid, _phoneController.text);
        
        // Refresh UserProvider to trigger Root navigation
        await userProvider.init(user.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(32),
              opacity: 0.1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phonelink_ring_rounded, color: AppColors.primary, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    _otpSent ? 'Enter OTP' : 'Verify Phone',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textHigh),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _otpSent ? 'Sent to ${_phoneController.text}' : 'We need your number for logistical updates.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textLow),
                  ),
                  const SizedBox(height: 32),
                  if (!_otpSent)
                    KraveTextField(
                      label: 'Phone Number',
                      hintText: '+91 00000 00000',
                      prefixIcon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => _phoneController.text = v,
                    )
                  else
                    KraveTextField(
                      label: 'One-Time Password',
                      hintText: '      • • • • • •',
                      prefixIcon: Icons.lock_person_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _otpController.text = v,
                    ),
                  const SizedBox(height: 32),
                  KraveButton(
                    text: _otpSent ? 'Verify' : 'Send Code',
                    isLoading: _loading,
                    onPressed: _otpSent ? _verifyOTP : _sendOTP,
                    icon: _otpSent ? Icons.check_circle_rounded : Icons.send_rounded,
                  ),
                  if (_otpSent)
                    TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: const Text('Change Number', style: TextStyle(color: AppColors.primary)),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
        ),
      ),
    );
  }
}
