import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/canteen_model.dart';
import '../screens/user/canteen_menu.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';
import '../theme/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/location_helper.dart';

class RestaurantCard extends StatelessWidget {
  final Canteen canteen;
  final Position? userPosition;
  
  const RestaurantCard({super.key, required this.canteen, this.userPosition});

  @override
  Widget build(BuildContext context) {
    final isClosed = canteen.status == VenueStatus.closed;
    
    String distanceStr = 'Near you';
    if (userPosition != null) {
      final distance = LocationHelper.calculateDistance(
        userPosition!.latitude, 
        userPosition!.longitude, 
        canteen.latitude, 
        canteen.longitude,
      );
      distanceStr = distance < 1000 
          ? '${distance.toStringAsFixed(0)}m' 
          : '${(distance / 1000).toStringAsFixed(1)}km';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => CanteenMenu(canteen: canteen)));
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
                    ColorFiltered(
                      colorFilter: isClosed 
                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: CachedNetworkImage(
                        imageUrl: canteen.image ?? 'https://loremflickr.com/640/360/food?lock=${canteen.id.hashCode}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildStatusBadge(canteen.status),
                    ),
                    // Rating Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        borderRadius: BorderRadius.circular(8),
                        opacity: 0.2,
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              canteen.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Prep Time
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        borderRadius: BorderRadius.circular(8),
                        opacity: 0.1,
                        child: Text(
                          '${canteen.avgPrepTime} mins',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            canteen.name,
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isClosed ? AppColors.textLow : AppColors.textHigh),
                          ),
                        ),
                        Text(
                          distanceStr, 
                          style: TextStyle(color: AppColors.textLow, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canteen.categories.isEmpty ? 'Restaurant' : canteen.categories.join(' • '),
                      style: TextStyle(color: AppColors.textMed, fontSize: 13),
                    ),
                    if (isClosed)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Currently not accepting orders',
                          style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
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

  Widget _buildStatusBadge(VenueStatus status) {
    Color color;
    String label;
    switch (status) {
      case VenueStatus.open:
        color = const Color(0xFF10B981);
        label = 'OPEN';
        break;
      case VenueStatus.busy:
        color = Colors.orangeAccent;
        label = 'BUSY';
        break;
      case VenueStatus.closed:
        color = Colors.redAccent;
        label = 'CLOSED';
        break;
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      borderRadius: BorderRadius.circular(8),
      opacity: 0.2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
