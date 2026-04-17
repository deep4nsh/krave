import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/canteen_model.dart';
import '../screens/user/canteen_menu.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';

import 'package:geolocator/geolocator.dart';
import '../utils/location_helper.dart';

class RestaurantCard extends StatelessWidget {
  final Canteen canteen;
  final Position? userPosition;
  
  const RestaurantCard({super.key, required this.canteen, this.userPosition});

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

    final isRestaurant = canteen.type == VenueType.restaurant;
    final label = isRestaurant ? 'Restaurant' : 'Canteen';

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
                  'Edit $label Timings',
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
    final isRestaurant = canteen.type == VenueType.restaurant;
    
    String distanceStr = 'Near you';
    if (userPosition != null) {
      final distance = LocationHelper.calculateDistance(
        userPosition!.latitude, 
        userPosition!.longitude, 
        canteen.latitude, 
        canteen.longitude,
      );
      if (distance < 1000) {
        distanceStr = '${distance.toStringAsFixed(0)}m away';
      } else {
        distanceStr = '${(distance / 1000).toStringAsFixed(1)}km away';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
              // Image Section with stacked glass effect
              SizedBox(
                height: 200,
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
                              theme.colorScheme.surface,
                              theme.colorScheme.background,
                            ],
                          ),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surface,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Glass Label for Status
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        borderRadius: BorderRadius.circular(10),
                        opacity: 0.2,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'OPEN',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Venue Type Badge
                    Positioned(
                      top: 16,
                      right: isOwner ? 16 + 50 : 16, // Shift if edit button is there
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        borderRadius: BorderRadius.circular(10),
                        opacity: 0.2,
                        child: Row(
                          children: [
                            Icon(isRestaurant ? Icons.restaurant_rounded : Icons.lunch_dining_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              isRestaurant ? 'RESTRO' : 'CANTEEN',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GlassContainer(
                          borderRadius: BorderRadius.circular(12),
                          opacity: 0.2,
                          child: IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                            onPressed: () => _showEditTimingsDialog(context),
                            tooltip: 'Edit Timings',
                          ),
                        ),
                      ),
                    // Bottom info on image
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '4.5',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '20-30 min',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canteen.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          '${isRestaurant ? 'External' : 'Campus'} • $distanceStr',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Dynamic Promo Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            isRestaurant ? 'Special Welcome Offer' : 'Flat 50% OFF up to ₹100',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
