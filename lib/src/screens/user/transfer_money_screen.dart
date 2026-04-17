import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firestore_service.dart';
import '../../services/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/krave_loading.dart';

class TransferMoneyScreen extends StatefulWidget {
  const TransferMoneyScreen({super.key});

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  void _handleTransfer() async {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();
    
    if (phone.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all details.')));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount.')));
      return;
    }

    final userProvider = context.read<UserProvider>();
    if (userProvider.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient wallet balance.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fs = context.read<FirestoreService>();
      await fs.transferWalletBalance(
        senderId: userProvider.user!.id,
        receiverPhone: phone,
        amount: amount,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        color: AppColors.primary,
        opacity: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Colors.black),
            const SizedBox(height: 24),
            Text('Treat Sent!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            const Text('Your friend will see the balance instantly.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Go back to profile
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Treat a Friend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SEND CAMPUS CURRENCY', style: GoogleFonts.outfit(color: AppColors.primary, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Send money to any student using their registered phone number.', style: TextStyle(color: AppColors.textLow)),
              const SizedBox(height: 40),
              
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(24),
                opacity: 0.05,
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Friend\'s Phone Number',
                        labelStyle: const TextStyle(color: AppColors.textLow),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        labelStyle: const TextStyle(color: AppColors.textLow),
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.primary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('SEND TREAT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
