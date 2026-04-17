import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
    {'id': 'aadhaar_front', 'title': 'Aadhaar Card (Front)', 'desc': 'Clear photo of front side'},
    {'id': 'aadhaar_back', 'title': 'Aadhaar Card (Back)', 'desc': 'Clear photo of back side'},
    {'id': 'pan_card', 'title': 'PAN Card', 'desc': 'Clear photo of front side'},
    {'id': 'driving_licence', 'title': 'Driving Licence', 'desc': 'Clear photo showing details'},
    {'id': 'vehicle_rc', 'title': 'Vehicle RC', 'desc': 'Registration certificate'},
    {'id': 'bank_passbook', 'title': 'Bank Passbook / Cheque', 'desc': 'Showing Acct No. & IFSC'},
    {'id': 'live_selfie', 'title': 'Live Selfie', 'desc': 'Take a clear selfie'},
  ];

  Future<void> _pickAndUpload(String docId, {bool selfie = false}) async {
    final auth = context.read<AuthProvider>();
    final XFile? image = await _picker.pickImage(
      source: selfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _uploadProgress[docId] = 0.01);
      await auth.uploadKycDocument(docId, File(image.path), (progress) {
        setState(() {
          _uploadProgress[docId] = progress;
        });
      });
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
    
    // Check if all documents are uploaded
    bool allUploaded = _requiredDocs.every((doc) => kycDetails.containsKey(doc['id']));

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Document Upload'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= 1 ? AppTheme.accent : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Upload your documents to proceed. Files are encrypted and stored securely.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _requiredDocs.length,
                itemBuilder: (context, index) {
                  final doc = _requiredDocs[index];
                  final docId = doc['id']!;
                  final isUploaded = kycDetails.containsKey(docId);
                  final progress = _uploadProgress[docId];
                  final isSelfie = docId == 'live_selfie';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isUploaded ? Colors.green.withOpacity(0.1) : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isUploaded ? Icons.check_circle_rounded : Icons.file_upload_outlined,
                            color: isUploaded ? Colors.green : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              if (progress != null)
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppTheme.border,
                                  color: AppTheme.accent,
                                )
                              else
                                Text(
                                  isUploaded ? 'Uploaded (Pending Verification)' : doc['desc']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isUploaded ? Colors.green : AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (progress == null)
                          TextButton(
                            onPressed: () => _pickAndUpload(docId, selfie: isSelfie),
                            style: TextButton.styleFrom(
                              foregroundColor: isUploaded ? AppTheme.textMuted : AppTheme.accent,
                            ),
                            child: Text(isUploaded ? 'Retake' : 'Upload'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: allUploaded ? _submitForVerification : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: auth.state == AuthState.loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Submit for Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
