import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../owner/waiting_approval_screen.dart'; // 👈 Make sure you have this

class OwnerHome extends StatefulWidget {
  const OwnerHome({Key? key}) : super(key: key);

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  String? canteenId;
  String? ownerStatus;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
  }

  Future<void> _checkOwnerStatus() async {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final firestore = FirestoreService();
    final ownerDoc = await firestore.getOwnerDoc(uid); // 👈 We'll add this function below

    if (ownerDoc == null) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
      return;
    }

    setState(() {
      ownerStatus = ownerDoc['status'];
      canteenId = ownerDoc['canteen_id']; // optional if stored
      loading = false;
    });

    // 🚫 If still pending or rejected, redirect to waiting/denied screen
    if (ownerStatus == 'pending' || ownerStatus == 'rejected') {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krave - Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: canteenId == null
          ? const Center(child: Text('No canteen assigned yet. Contact Admin.'))
          : StreamBuilder<List<OrderModel>>(
        stream: fs.streamOrdersForCanteen(canteenId!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('Token: ${o.tokenNumber} • ₹${o.totalAmount}'),
                  subtitle: Text('Status: ${o.status}\nItems: ${o.items.map((e) => e['name']).join(', ')}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'Pending' || value == 'Ready' || value == 'Completed') {
                        await fs.updateOrderStatus(o.id, value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order ${o.id} set to $value')),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Pending', child: Text('Set Pending')),
                      PopupMenuItem(value: 'Ready', child: Text('Set Ready')),
                      PopupMenuItem(value: 'Completed', child: Text('Set Completed')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.menu_book),
        onPressed: () {
          // Add manage menu navigation here
        },
      ),
    );
  }
}