import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/canteen_model.dart';
import '../../services/firestore_service.dart';

class ManageCanteensScreen extends StatelessWidget {
  const ManageCanteensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Canteens'),
      ),
      body: StreamBuilder<List<Canteen>>(
        stream: fs.streamApprovedCanteens(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final canteens = snapshot.data ?? [];
          if (canteens.isEmpty) {
            return const Center(child: Text('No approved canteens found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: canteens.length,
            itemBuilder: (context, index) {
              final canteen = canteens[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(canteen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Owner ID: ${canteen.ownerId}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'Revoke Approval',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Revoke Approval?'),
                          content: Text('Are you sure you want to remove "${canteen.name}"? This will revert the owner to pending status.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Revoke'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await fs.revokeCanteenApproval(canteen.id, canteen.ownerId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Canteen approval revoked.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
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
