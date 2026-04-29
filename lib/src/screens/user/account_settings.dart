import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/user_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/krave_button.dart';
import '../../theme/app_colors.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _hostelController;
  late TextEditingController _roomController;
  late TextEditingController _specController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _hostelController = TextEditingController(text: user?.address?['hostel'] ?? '');
    _roomController = TextEditingController(text: user?.address?['room'] ?? '');
    _specController = TextEditingController(text: user?.address?['spec'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hostelController.dispose();
    _roomController.dispose();
    _specController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final uid = context.read<UserProvider>().user!.id;
      final fs = context.read<FirestoreService>();
      
      await fs.updateUserProfile(uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': {
          'hostel': _hostelController.text.trim(),
          'room': _roomController.text.trim(),
          'spec': _specController.text.trim(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Account Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Personal Details'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_rounded,
                  validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.length < 10 ? 'Invalid phone number' : null,
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Delivery Address (Hostel)'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hostelController,
                  label: 'Hostel Name',
                  icon: Icons.apartment_rounded,
                  hint: 'e.g., Ramanujan Hostel',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _roomController,
                  label: 'Room Number',
                  icon: Icons.meeting_room_rounded,
                  hint: 'e.g., 101-B',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specController,
                  label: 'Specific Directions',
                  icon: Icons.description_rounded,
                  hint: 'e.g., Near the elevator',
                  maxLines: 2,
                ),
                
                const SizedBox(height: 48),
                KraveButton(
                  text: 'Save Settings',
                  isLoading: _isLoading,
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(16),
      opacity: 0.05,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary, size: 22),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textLow, fontSize: 14),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}
