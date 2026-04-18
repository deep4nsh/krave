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
import 'otp_verification_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    
    setState(() => _loading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _loading = false);
      
      // Navigate to OTP page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(phoneNumber: phone),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock OTP "123456" sent!')),
      );
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
                    'Verify Phone',
                    style: GoogleFonts.outfit(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textHigh,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We need your number for logistical updates and delivery tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLow),
                  ),
                  const SizedBox(height: 32),
                  KraveTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hintText: '+91 00000 00000',
                    prefixIcon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.send,
                  ),
                  const SizedBox(height: 32),
                  KraveButton(
                    text: 'Send Code',
                    isLoading: _loading,
                    onPressed: _sendOTP,
                    icon: Icons.send_rounded,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
