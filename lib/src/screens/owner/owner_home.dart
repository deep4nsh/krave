// lib/screens/owner/owner_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({Key? key}) : super(key: key);

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  String? canteenId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final fs = Provider.of<FirestoreService>(context, listen: false);
    // Option 1: if you stored canteenId in Users doc
    final user = await fs.getUser(uid);
    setState(() {
      canteenId = user?.canteenId; // may be null if owner not assigned a canteen yet
      loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krave - Owner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : canteenId == null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No canteen assigned to your account yet.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // If you have Manage Canteen flow, navigate there
              },
              child: const Text('Request Canteen / Contact Admin'),
            ),
          ],
        ),
      )
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${o.id} set to $value')));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'Pending', child: Text('Set Pending')),
                      const PopupMenuItem(value: 'Ready', child: Text('Set Ready')),
                      const PopupMenuItem(value: 'Completed', child: Text('Set Completed')),
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
          // Navigate to Manage Menu screen if you have it
        },
      ),
    );
  }
}