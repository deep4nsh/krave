// lib/screens/admin/admin_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({Key? key}) : super(key: key);

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Owners'),
              Tab(text: 'Canteens'),
              Tab(text: 'Orders'),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // =================== PENDING OWNERS ===================
            StreamBuilder<QuerySnapshot>(
              stream: fs.streamPendingOwners(), // from FirestoreService
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('✅ No pending owners.'));
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final owner = docs[i];
                    final ownerName = owner['name'] ?? 'Unknown';
                    final ownerEmail = owner['email'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(ownerName),
                        subtitle: Text(ownerEmail),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: 'Approve',
                              onPressed: () async {
                                final confirm = await _confirmAction(
                                  context,
                                  'Approve $ownerName?',
                                  'This will mark this owner as approved.',
                                );
                                if (confirm == true) {
                                  await fs.approveOwner(owner.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$ownerName approved ✅')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () async {
                                final confirm = await _confirmAction(
                                  context,
                                  'Reject $ownerName?',
                                  'This will permanently remove this owner.',
                                );
                                if (confirm == true) {
                                  await fs.rejectOwner(owner.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$ownerName rejected ❌')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // =================== CANTEENS TAB ===================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Canteens').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No canteens available.'));
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final canteen = docs[i];
                    final name = canteen['canteen_name'] ?? 'Unnamed';
                    final ownerId = canteen['ownerId'] ?? 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text('Owner ID: $ownerId'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await _confirmAction(
                              context,
                              'Delete Canteen?',
                              'This will remove "$name" from database.',
                            );
                            if (confirm == true) {
                              await canteen.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Canteen "$name" deleted 🗑️')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // =================== ORDERS TAB ===================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Orders')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final order = docs[i];
                    final token = order['tokenNumber'] ?? 'N/A';
                    final user = order['userId'] ?? 'Unknown';
                    final canteen = order['canteenId'] ?? 'Unknown';
                    final status = order['status'] ?? 'Pending';
                    final total = order['totalAmount'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('Order #$token - $status'),
                        subtitle: Text('User: $user\nCanteen: $canteen\nTotal: ₹$total'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            FirebaseFirestore.instance
                                .collection('Orders')
                                .doc(order.id)
                                .update({'status': val});
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'Pending', child: Text('Pending')),
                            PopupMenuItem(value: 'Completed', child: Text('Completed')),
                            PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmation dialog helper
  Future<bool?> _confirmAction(BuildContext context, String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
  }
}