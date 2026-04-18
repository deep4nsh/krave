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

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;

  Future<void> _verifyOTP() async {
    HapticFeedback.lightImpact();
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        _kraveSnackBar('Please enter the full 6-digit code.'),
      );
      return;
    }

    if (_otpController.text != '123456') {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        _kraveSnackBar('Invalid OTP! (Try 123456)', isError: true),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final userProvider = context.read<UserProvider>();

    try {
      final user = auth.currentUser;
      if (user != null) {
        // Update user profile with phone number (passed from previous screen)
        await fs.updateUserPhone(user.uid, widget.phoneNumber);
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          // Refresh UserProvider to trigger Root navigation to Home
          await userProvider.initializeSession(user.uid);
          
          if (mounted) {
            // Pop back to Root which will now show UserHome
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          _kraveSnackBar('Error: ${e.toString()}', isError: true),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  SnackBar _kraveSnackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(
        message,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHigh),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
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
                  const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    'Enter OTP',
                    style: GoogleFonts.outfit(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textHigh,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sent to ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textLow),
                  ),
                  const SizedBox(height: 32),
                  KraveTextField(
                    controller: _otpController,
                    label: 'One-Time Password',
                    hintText: '• • • • • •',
                    prefixIcon: Icons.vpn_key_rounded,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  KraveButton(
                    text: 'Verify',
                    isLoading: _loading,
                    onPressed: _verifyOTP,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        _kraveSnackBar('Mock OTP "123456" resent!'),
                      );
                    },
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
    _otpController.dispose();
    super.dispose();
  }
}
