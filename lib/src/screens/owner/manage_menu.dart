import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_item_model.dart';
import '../../services/firestore_service.dart';

// This widget is now much simpler, as it doesn't manage its own Scaffold or FAB
class ManageMenu extends StatelessWidget {
  final String canteenId;
  const ManageMenu({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return StreamBuilder<List<MenuItemModel>>(
      stream: fs.streamMenuItems(canteenId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text('No menu items yet.\nPress the + button to add one.'),
          );
        }
        // The ListView now has bottom padding to ensure the last item is not hidden
        // by the floating action button or the bottom navigation bar.
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
          itemCount: items.length,
          itemBuilder: (context, i) {
            return _MenuItemTile(canteenId: canteenId, item: items[i]);
          },
        );
      },
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
        title: Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text('${item.category} - ₹${item.price}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        trailing: IconButton(
          tooltip: 'Delete Item',
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => fs.deleteMenuItem(canteenId, item.id),
        ),
      ),
    );
  }
}
