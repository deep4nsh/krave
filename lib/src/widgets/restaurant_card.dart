import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/canteen_model.dart';
import '../screens/user/canteen_menu.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';

class RestaurantCard extends StatelessWidget {
  final Canteen canteen;
  
  const RestaurantCard({super.key, required this.canteen});

  Future<void> _showEditTimingsDialog(BuildContext context) async {
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;

    // Helper to parse "HH:MM AM/PM" string to TimeOfDay
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      try {
        final parts = timeStr.split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);
        final bool isPm = parts[1].toUpperCase() == 'PM';
        
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return null;
      }
    }

    // Initialize with current values if available
    openingTime = parseTime(canteen.openingTime);
    closingTime = parseTime(canteen.closingTime);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          opacity: 0.95,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Canteen Timings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) => Column(
                    children: [
                      ListTile(
                        title: const Text('Opening Time'),
                        trailing: Text(openingTime?.format(context) ?? 'Select'),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: openingTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() => openingTime = time);
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('Closing Time'),
                        trailing: Text(closingTime?.format(context) ?? 'Select'),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: closingTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (time != null) {
                            setState(() => closingTime = time);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (openingTime != null && closingTime != null) {
                          try {
                            await context.read<FirestoreService>().updateCanteenTimings(
                              canteen.id,
                              openingTime!.format(context),
                              closingTime!.format(context),
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating timings: $e')),
                              );
                            }
                          }
                        } else {
                           if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select both opening and closing times')),
                              );
                            }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().currentUser;
    final isOwner = user?.uid == canteen.ownerId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CanteenMenu(canteen: canteen)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://loremflickr.com/640/360/food,restaurant/all?lock=${canteen.id.hashCode}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.8),
                            theme.colorScheme.secondary.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.store_mall_directory,
                          size: 64,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                    ),
                  ),
                  // Gradient Overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  if (isOwner)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditTimingsDialog(context),
                        tooltip: 'Edit Timings',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          canteen.name,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '4.2', // Hardcoded rating for now
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Meta Info Row (Time, Delivery)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        canteen.openingTime != null 
                            ? '${canteen.openingTime} - ${canteen.closingTime}' 
                            : 'Timings not set',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.delivery_dining, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Free Delivery',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Dotted Divider
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (_) => SizedBox(
                            width: 5,
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: theme.dividerColor),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Offers Section
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        '60% OFF up to ₹120',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
