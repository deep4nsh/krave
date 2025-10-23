import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../owner/waiting_approval_screen.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

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
    final ownerDoc = await firestore.getOwnerDoc(uid);

    if (ownerDoc == null) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
      return;
    }

    setState(() {
      ownerStatus = ownerDoc['status'];
      canteenId = ownerDoc['canteen_id'];
      loading = false;
    });

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
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: canteenId == null
          ? const Center(child: Text('No canteen assigned yet. Contact Admin.'))
          : _buildDashboard(context, fs),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: "Add Menu Item",
        onPressed: () => _showAddMenuDialog(context, fs),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, FirestoreService fs) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: "Orders"),
              Tab(icon: Icon(Icons.restaurant_menu), text: "Menu"),
              Tab(icon: Icon(Icons.inventory), text: "Inventory"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrdersTab(fs),
                _buildMenuTab(fs),
                _buildInventoryTab(fs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== ORDERS TAB ==================
  Widget _buildOrdersTab(FirestoreService fs) {
    return StreamBuilder<List<OrderModel>>(
      stream: fs.streamOrdersForCanteen(canteenId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('No orders yet.'));
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Token: ${o.tokenNumber} • ₹${o.totalAmount}'),
                subtitle: Text('Status: ${o.status}\nItems: ${o.items.map((e) => e['name']).join(', ')}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    await fs.updateOrderStatus(o.id, value);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Order set to $value')));
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Pending', child: Text('Pending')),
                    PopupMenuItem(value: 'Ready', child: Text('Ready')),
                    PopupMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================== MENU TAB ==================
  Widget _buildMenuTab(FirestoreService fs) {
    return StreamBuilder(
      stream: fs.streamMenuItems(canteenId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('No menu items yet.'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return ListTile(
              title: Text(item.name),
              subtitle: Text("₹${item.price} • ${item.available ? 'Available' : 'Out of Stock'}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => fs.deleteMenuItem(canteenId!, item.id),
              ),
              onTap: () => _showEditMenuDialog(context, fs, item.id, item.name, item.price),
            );
          },
        );
      },
    );
  }

  // ================== INVENTORY TAB ==================
  Widget _buildInventoryTab(FirestoreService fs) {
    return StreamBuilder<QuerySnapshot>(
      stream: fs.streamInventory(canteenId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No inventory items.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? 'Unnamed'),
              subtitle: Text("Qty: ${data['quantity']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => fs.deleteInventoryItem(canteenId!, docs[i].id),
              ),
            );
          },
        );
      },
    );
  }

  // ================== DIALOGS ==================
  void _showAddMenuDialog(BuildContext context, FirestoreService fs) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await fs.addMenuItem(canteenId!, {
                'name': nameCtrl.text,
                'price': int.parse(priceCtrl.text),
                'available': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMenuDialog(BuildContext context, FirestoreService fs, String itemId, String name, int price) {
    final nameCtrl = TextEditingController(text: name);
    final priceCtrl = TextEditingController(text: price.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await fs.updateMenuItem(canteenId!, itemId, {
                'name': nameCtrl.text,
                'price': int.parse(priceCtrl.text),
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}