import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // ================= CHECK OWNER STATUS =================
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

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // ================= MAIN BUILD =================
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
        tooltip: "Add Menu Item",
        onPressed: () => _showAddMenuDialog(context, fs),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= DASHBOARD LAYOUT =================
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
              Tab(icon: Icon(Icons.inventory_2), text: "Inventory"),
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

  // ================= ORDERS TAB =================
  Widget _buildOrdersTab(FirestoreService fs) {
    return StreamBuilder<List<OrderModel>>(
      stream: fs.streamOrdersForCanteen(canteenId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }

        // Order status summary
        final pending = orders.where((o) => o.status == 'Pending').length;
        final ready = orders.where((o) => o.status == 'Ready').length;
        final completed = orders.where((o) => o.status == 'Completed').length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusChip('Pending', pending, Colors.orange),
                  _statusChip('Ready', ready, Colors.blue),
                  _statusChip('Completed', completed, Colors.green),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final o = orders[i];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Token: ${o.tokenNumber} • ₹${o.totalAmount}'),
                      subtitle: Text(
                          'Status: ${o.status}\nItems: ${o.items.map((e) => e['name']).join(', ')}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          await fs.updateOrderStatus(o.id, value);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Order set to $value')),
                          );
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count', style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  // ================= MENU TAB =================
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
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: item.imageUrl != null
                    ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.fastfood, color: Colors.deepOrange),
                title: Text(item.name),
                subtitle: Text("₹${item.price} • ${item.available ? 'Available' : 'Out of Stock'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: item.available,
                      activeThumbColor: Colors.green,
                      onChanged: (val) => fs.updateMenuItem(canteenId!, item.id, {'available': val}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => fs.deleteMenuItem(canteenId!, item.id),
                    ),
                  ],
                ),
                onTap: () => _showEditMenuDialog(context, fs, item.id, item.name, item.price),
              ),
            );
          },
        );
      },
    );
  }

  // ================= ADD MENU ITEM =================
  void _showAddMenuDialog(BuildContext context, FirestoreService fs) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    File? imageFile;

    Future<void> pickImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) imageFile = File(picked.path);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and price')));
                return;
              }

              String? imageUrl;
              if (imageFile != null) {
                final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                final ref = FirebaseStorage.instance.ref().child('canteen_menu/${canteenId!}/$filename');
                await ref.putFile(imageFile!, SettableMetadata(contentType: 'image/jpeg'));
                imageUrl = await ref.getDownloadURL();
              }

              await fs.addMenuItem(canteenId!, {
                'name': nameCtrl.text.trim(),
                'price': int.parse(priceCtrl.text),
                'available': true,
                'imageUrl': imageUrl,
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

  // ================= EDIT MENU ITEM =================
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

  // ================= INVENTORY TAB =================
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
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () => fs.updateInventoryItem(canteenId!, docs[i].id, {'quantity': (data['quantity'] ?? 0) + 1}),
              ),
            );
          },
        );
      },
    );
  }
}