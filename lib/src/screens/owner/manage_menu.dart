import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final fs = context.read<FirestoreService>();

    return Opacity(
      opacity: item.available ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.photoUrl ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 60, height: 60, color: Colors.white12,
                  child: const Icon(Icons.fastfood_rounded, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    '₹${item.price} • ${item.category}',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Availability Switch
            Switch(
              value: item.available,
              activeColor: const Color(0xFF10b981),
              onChanged: (val) {
                fs.updateDoc(
                  'Canteens/$canteenId/MenuItems/${item.id}',
                  {'available': val, 'updatedAt': FieldValue.serverTimestamp()}
                );
              },
            ),
            
            // Delete Action
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => fs.deleteMenuItem(canteenId, item.id),
            ),
          ],
        ),
      ),
    );
  }
}
