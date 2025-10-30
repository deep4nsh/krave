import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';

class OwnerApprovalScreen extends StatelessWidget {
  const OwnerApprovalScreen({super.key});

  void _showConfirmationDialog(BuildContext context, String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(child: Text(title), onPressed: () {
            onConfirm();
            Navigator.of(ctx).pop();
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: StreamBuilder<QuerySnapshot>(
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
            padding: const EdgeInsets.all(8.0),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final owner = docs[i].data() as Map<String, dynamic>;
              final ownerId = docs[i].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner['name'] ?? 'No Name', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('Email: ${owner['email'] ?? 'N/A'}'),
                      Text('Canteen: ${owner['canteen_name'] ?? 'N/A'}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _showConfirmationDialog(
                              context, 'Reject', 'Are you sure you want to reject this owner?', 
                              () => fs.rejectOwner(ownerId)),
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showConfirmationDialog(
                              context, 'Approve', 'Are you sure you want to approve this owner?', 
                              () => fs.approveOwner(ownerId)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
    );
  }
}
