import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        title: const Text('Basic Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Progress indicator
              Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == 0 ? AppTheme.accent : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tell us about yourself',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 1 of 6: Basic details',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded, color: AppTheme.textMuted)),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_rounded, color: AppTheme.textMuted)),
                validator: (v) => v!.isEmpty ? 'City is required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.two_wheeler_rounded, color: AppTheme.textMuted)),
                items: ['Bike', 'Scooter', 'Cycle']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: AppTheme.textPrimary))))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
                dropdownColor: AppTheme.surfaceLight,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (Optional)', prefixIcon: Icon(Icons.email_rounded, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 32),

              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(auth.error!, style: const TextStyle(color: AppTheme.accentRed, fontSize: 13)),
                ),

              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Continue to Next Step'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
