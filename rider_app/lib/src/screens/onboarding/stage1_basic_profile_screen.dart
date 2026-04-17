import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class Stage1BasicProfileScreen extends StatefulWidget {
  const Stage1BasicProfileScreen({super.key});

  @override
  State<Stage1BasicProfileScreen> createState() => _Stage1BasicProfileScreenState();
}

class _Stage1BasicProfileScreenState extends State<Stage1BasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _vehicleType = 'Bike';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().updateBasicProfile(
          _nameCtrl.text.trim(),
          _cityCtrl.text.trim(),
          _vehicleType,
          _emailCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.state == AuthState.loading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.5),
                  border: const Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: List.generate(6, (index) {
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == 0 ? AppTheme.primary : AppTheme.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }),
                    ).animate().fadeIn().scaleX(begin: 0.8),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('STEP 01/06',
                            style: GoogleFonts.outfit(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.5)),
                        Text('BASIC PROFILE',
                            style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.5)),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  children: [
                    Text(
                      'Welcome to Krave!',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                    ).animate().fadeIn().slideX(begin: -0.1),
                    const SizedBox(height: 12),
                    Text(
                      'Tell us a bit about yourself to get started on your journey.',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 15),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 48),

                    _buildFieldHeader('WHAT IS YOUR NAME?'),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration('Full Name', Icons.person_rounded),
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 32),

                    _buildFieldHeader('WHERE DO YOU LIVE?'),
                    TextFormField(
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration('Enter City', Icons.location_on_rounded),
                      validator: (v) => v!.isEmpty ? 'City is required' : null,
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 32),

                    _buildFieldHeader('YOUR VEHICLE'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _vehicleType,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(border: InputBorder.none),
                        items: ['Bike', 'Scooter', 'Cycle']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => setState(() => _vehicleType = v!),
                        dropdownColor: AppTheme.surface,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 48),

                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(auth.error!, style: GoogleFonts.outfit(color: AppTheme.accentRed, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                      : Text('CONTINUE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ).animate().slideY(begin: 0.2).fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16),
    );
  }
}
