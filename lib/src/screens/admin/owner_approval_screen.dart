import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_background.dart'; // Import the gradient background

class OwnerApprovalScreen extends StatelessWidget {
  const OwnerApprovalScreen({super.key});

  void _showConfirmationDialog(BuildContext context, String title, String content, VoidCallback onConfirm, Color buttonColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: Colors.black),
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
      body: GradientBackground(
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
              return const Center(child: Text("No pending owners to approve.", style: TextStyle(fontSize: 18)));
            }

            final docs = snap.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final owner = docs[i].data() as Map<String, dynamic>;
                final ownerId = docs[i].id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(owner['name'] ?? 'No Name', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: 'Email: ', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                          TextSpan(text: owner['email'] ?? 'N/A', style: theme.textTheme.bodyLarge),
                        ])),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: 'Canteen: ', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                          TextSpan(text: owner['canteen_name'] ?? 'N/A', style: theme.textTheme.bodyLarge),
                        ])),
                        const Divider(height: 24),
                        // DEFINITIVE FIX: Use ButtonBar to correctly handle button constraints
                        ButtonBar(
                          children: [
                            TextButton(
                              onPressed: () => _showConfirmationDialog(
                                context, 'Reject', 'Are you sure you want to reject this owner and delete their account?', 
                                () => fs.rejectOwner(ownerId), Colors.redAccent),
                              child: const Text('Reject'),
                            ),
                            ElevatedButton(
                              onPressed: () => _showConfirmationDialog(
                                context, 'Approve', 'Are you sure you want to approve this owner?', 
                                () => fs.approveOwner(ownerId), theme.colorScheme.primary),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
