import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';
import '../../services/image_search_service.dart';

class ManageMenu extends StatefulWidget {
  final String canteenId;
  const ManageMenu({super.key, required this.canteenId});

  @override
  State<ManageMenu> createState() => _ManageMenuState();
}

class _ManageMenuState extends State<ManageMenu> {
  bool _isFetchingImages = false;

  Future<void> _batchFetchImages() async {
    final fs = context.read<FirestoreService>();
    final imageSearch = context.read<ImageSearchService>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isFetchingImages = true);

    try {
      final snapshot = await fs.streamMenuItems(widget.canteenId).first;
      final itemsWithoutImages = snapshot.where((item) => item.photoUrl == null || item.photoUrl!.isEmpty).toList();
      
      if (itemsWithoutImages.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('All items already have images!')));
        setState(() => _isFetchingImages = false);
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text('Fetching images for ${itemsWithoutImages.length} items...')));

      int successCount = 0;
      for (final item in itemsWithoutImages) {
        final imageUrl = await imageSearch.searchImage(item.name);
        if (imageUrl != null) {
          await fs.updateMenuItem(widget.canteenId, item.id, {'photoUrl': imageUrl});
          successCount++;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      messenger.showSnackBar(SnackBar(
        content: Text('Successfully fetched images for $successCount/${itemsWithoutImages.length} items'),
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isFetchingImages = false);
    }
  }

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
                      const Text('Searching for image and saving...'),
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
                    final imageSearch = context.read<ImageSearchService>();
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
                      final imageUrl = await imageSearch.searchImage(name);

                      await fs.addMenuItem(widget.canteenId, {
                        'name': name,
                        'price': parsedPrice,
                        'category': category,
                        'available': true,
                        'photoUrl': imageUrl,
                      });
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
                      setDialogState(() => isSaving = false);
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
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          if (_isFetchingImages)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Auto-fetch images for items without images',
              onPressed: _batchFetchImages,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMenuItemDialog,
        label: const Text('ADD ITEM'),
        icon: const Icon(Icons.add),
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
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, i) {
              return _MenuItemTile(canteenId: widget.canteenId, item: items[i]);
            },
          );
        },
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final String canteenId;
  final MenuItemModel item;

  const _MenuItemTile({required this.canteenId, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fs = context.read<FirestoreService>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: item.photoUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black12),
              errorWidget: (context, url, error) => Container(
                color: Colors.black12,
                child: Icon(Icons.fastfood, color: theme.colorScheme.primary, size: 30),
              ),
            ),
          ),
        ),
        title: Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.category} - ₹${item.price}', style: theme.textTheme.bodyMedium),
        trailing: IconButton(
          tooltip: 'Delete Item',
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => fs.deleteMenuItem(canteenId, item.id),
        ),
      ),
    );
  }
}
