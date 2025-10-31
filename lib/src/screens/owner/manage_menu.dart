import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';

class ManageMenu extends StatefulWidget {
  final String canteenId;
  const ManageMenu({super.key, required this.canteenId});

  @override
  State<ManageMenu> createState() => _ManageMenuState();
}

class _ManageMenuState extends State<ManageMenu> {
  void _addMenuItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSaving) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      const Text('Saving item...'),
                    ] else ...[
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                      TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                      TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
                    ]
                  ],
                ),
              ),
              actions: isSaving ? [] : [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final fs = context.read<FirestoreService>();
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final name = nameCtrl.text.trim();
                    final priceText = priceCtrl.text.trim();
                    final category = categoryCtrl.text.trim();

                    if (name.isEmpty || priceText.isEmpty || category.isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('All fields are required.')));
                      return;
                    }
                    final parsedPrice = int.tryParse(priceText);
                    if (parsedPrice == null) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter a valid price.')));
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      await fs.addMenuItem(widget.canteenId, {
                        'name': name,
                        'price': parsedPrice,
                        'category': category,
                        'available': true,
                      });
                      navigator.pop(); // Close the dialog
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
                      setDialogState(() => isSaving = false); // Allow user to retry
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addMenuItemDialog,
        tooltip: 'Add Menu Item',
        child: const Icon(Icons.add), // FIX: Moved child to be the last property
      ),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: fs.streamMenuItems(widget.canteenId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No menu items yet.\nPress the + button to add one.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: const Icon(Icons.fastfood), // Placeholder icon
                title: Text(item.name),
                subtitle: Text("${item.category} - ₹${item.price}"),
                trailing: IconButton(
                  tooltip: 'Delete Item',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => fs.deleteMenuItem(widget.canteenId, item.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
