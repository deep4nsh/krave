import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class Stage2KycScreen extends StatefulWidget {
  const Stage2KycScreen({super.key});

  @override
  State<Stage2KycScreen> createState() => _Stage2KycScreenState();
}

class _Stage2KycScreenState extends State<Stage2KycScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, double> _uploadProgress = {};
  
  final List<Map<String, String>> _requiredDocs = [
    {'id': 'aadhaar_front', 'title': 'AADHAAR (FRONT)', 'desc': 'Show your photo & name'},
    {'id': 'aadhaar_back', 'title': 'AADHAAR (BACK)', 'desc': 'Show your address clearly'},
    {'id': 'pan_card', 'title': 'PAN CARD', 'desc': 'Original physical card photo'},
    {'id': 'driving_licence', 'title': 'DRIVING LICENCE', 'desc': 'Valid LMV or 2-Wheeler licence'},
    {'id': 'vehicle_rc', 'title': 'VEHICLE RC', 'desc': 'Registration certificate'},
    {'id': 'bank_passbook', 'title': 'BANK PASSBOOK', 'desc': 'Clearly show Account & IFSC'},
    {'id': 'live_selfie', 'title': 'LIVE SELFIE', 'desc': 'Take a clear photo of your face'},
  ];

  Future<void> _pickAndUpload(String docId, {bool selfie = false}) async {
    final auth = context.read<AuthProvider>();
    final XFile? image = await _picker.pickImage(
      source: selfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      if (!mounted) return;
      setState(() => _uploadProgress[docId] = 0.01);
      await auth.uploadKycDocument(docId, File(image.path), (progress) {
        if (!mounted) return;
        setState(() {
          _uploadProgress[docId] = progress;
        });
      });
      if (!mounted) return;
      setState(() => _uploadProgress.remove(docId));
    }
  }

  void _submitForVerification() {
    context.read<AuthProvider>().submitKycForVerification();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kycDetails = auth.rider?.kycDetails ?? {};
    bool allUploaded = _requiredDocs.every((doc) => kycDetails.containsKey(doc['id']));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
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
                            color: index <= 1 ? AppTheme.primary : AppTheme.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('STEP 02/06',
                          style: GoogleFonts.outfit(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5)),
                      Text('DOCUMENT UPLOAD',
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload Documents',
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data is encrypted and stored securely for verification only.',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  
                  ..._requiredDocs.map((doc) {
                    final docId = doc['id']!;
                    final isUploaded = kycDetails.containsKey(docId);
                    final progress = _uploadProgress[docId];
                    final isSelfie = docId == 'live_selfie';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isUploaded ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUploaded ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
                          width: isUploaded ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: progress != null ? null : () => _pickAndUpload(docId, selfie: isSelfie),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isUploaded ? AppTheme.primary : AppTheme.border.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isUploaded ? Icons.done_all_rounded : (isSelfie ? Icons.face_rounded : Icons.camera_alt_rounded),
                                  color: isUploaded ? Colors.black : AppTheme.textMuted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc['title']!,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    if (progress != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor: AppTheme.border,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    else
                                      Text(
                                        isUploaded ? 'UPLOADED SUCCESSFULLY' : doc['desc']!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: isUploaded ? FontWeight.bold : FontWeight.normal,
                                          color: isUploaded ? AppTheme.primary : AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isUploaded && progress == null)
                                const Icon(Icons.arrow_right_rounded, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05);
                  }).toList(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: allUploaded ? _submitForVerification : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: allUploaded ? AppTheme.primary : AppTheme.border,
                ),
                child: auth.state == AuthState.loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                    : Text('SUBMIT DATA', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
