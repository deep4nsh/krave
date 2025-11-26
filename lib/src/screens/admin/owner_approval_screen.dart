import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_background.dart'; // Import the gradient background

class OwnerApprovalScreen extends StatelessWidget {
  const OwnerApprovalScreen({super.key});

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
    Color buttonColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.black,
              // ---- FIRST FIX: ensure finite width/height locally ----
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(title),
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: fs.streamPendingOwners(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Center(
                child: Text("No pending owners to approve.", style: TextStyle(fontSize: 18)),
              );
            }

            final docs = snap.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final raw = docs[i].data();
                if (raw == null) return const SizedBox.shrink();

                final owner = raw as Map<String, dynamic>;
                final ownerId = docs[i].id;
                final name = owner['name'] as String? ?? 'No Name';
                final email = owner['email'] as String? ?? 'N/A';
                final canteenName = owner['canteen_name'] as String? ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: $email'),
                              const SizedBox(height: 4),
                              Text('Canteen: $canteenName', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                // Optional: also keep TextButton compact to avoid theme-induced issues
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _showConfirmationDialog(
                                  context,
                                  'Reject',
                                  'Are you sure you want to reject this owner and delete their account?',
                                  () => fs.rejectOwner(ownerId),
                                  Colors.redAccent,
                                ),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  // ---- FIRST FIX here as well ----
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _showConfirmationDialog(
                                  context,
                                  'Approve',
                                  'Are you sure you want to approve this owner?',
                                  () => fs.approveOwner(ownerId),
                                  theme.colorScheme.primary,
                                ),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
