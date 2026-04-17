import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    String phone = _phoneCtrl.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+91$phone'; // Default to India if no code
    }
    await context.read<AuthProvider>().sendOTP(phone);
  }

  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.length != 6) return;
    await context.read<AuthProvider>().verifyOTP(_otpCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.state == AuthState.loading;
    final isOtpMode = auth.state == AuthState.otpSent;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1117), Color(0xFF1A1D2E), Color(0xFF0F1117)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2),
                      ),
                      child: const Center(child: Text('🛵', style: TextStyle(fontSize: 36))),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Rider Onboarding',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOtpMode
                          ? 'Enter the 6-digit code sent to ${_phoneCtrl.text}'
                          : 'Enter your phone number to start',
                      style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 36),

                    if (!isOtpMode) ...[
                      // Phone Number Entry
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: const TextStyle(fontSize: 18, letterSpacing: 2),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixText: '+91 ',
                          prefixStyle: const TextStyle(fontSize: 18, color: AppTheme.textPrimary, letterSpacing: 2),
                          prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.textMuted),
                          counterText: '',
                        ),
                        validator: (v) => (v != null && v.length >= 10) ? null : 'Enter a valid 10-digit number',
                      ),
                    ] else ...[
                      // OTP Entry
                      Pinput(
                        length: 6,
                        controller: _otpCtrl,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyDecorationWith(
                          border: Border.all(color: AppTheme.accent),
                        ),
                        onCompleted: (pin) => _verifyOTP(),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Error
                    if (auth.state == AuthState.error && auth.error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                        ),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: AppTheme.accentRed, fontSize: 13),
                        ),
                      ),
                    
                    const SizedBox(height: 24),

                    // Primary Button
                    ElevatedButton(
                      onPressed: isLoading ? null : (isOtpMode ? _verifyOTP : _sendOTP),
                      child: isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(isOtpMode ? 'Verify & Continue' : 'Send OTP'),
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
