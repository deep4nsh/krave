import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import '../../utils/location_helper.dart';
import '../../theme/app_colors.dart';
import 'order_history.dart';
import 'profile_screen.dart';
import '../../widgets/skeleton_canteen_card.dart';
import '../../widgets/restaurant_card.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String _searchQuery = '';
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await LocationHelper.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _isLoadingLocation = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Fueling up for classes?';
    if (hour < 17) return 'Lunch break? We got you.';
    if (hour < 21) return 'Dinner is calling.';
    return 'Midnight cravings?';
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Elegant Background Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background.withOpacity(0.8),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                  title: Row(
                    children: [
                      Text(
                        'Krave',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: AppColors.textHigh,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('PRO', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                ),
                actions: [
                  IconButton(
                    icon: _AppBarAction(icon: Icons.history_rounded),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                  ),
                  IconButton(
                    icon: _AppBarAction(icon: Icons.person_outline_rounded),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        _getGreeting(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textMed,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Hero(
                        tag: 'search_bar',
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.glassBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: 'Search for cravings...',
                              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                              suffixIcon: Icon(Icons.tune_rounded, color: AppColors.textLow, size: 20),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              hintStyle: TextStyle(color: AppColors.textLow, fontSize: 15),
                            ),
                            style: const TextStyle(color: AppColors.textHigh),
                          ),
                        ),
                      ).animate().scale(delay: 300.ms, begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                    ),
                    // Categories Row
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _CategoryItem(label: 'All', icon: Icons.restaurant_rounded, isSelected: _searchQuery.isEmpty),
                          _CategoryItem(label: 'Burger', icon: Icons.lunch_dining_rounded),
                          _CategoryItem(label: 'Pizza', icon: Icons.local_pizza_rounded),
                          _CategoryItem(label: 'Coffee', icon: Icons.coffee_rounded),
                          _CategoryItem(label: 'Desert', icon: Icons.icecream_rounded),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Nearby Venues",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: AppColors.textHigh,
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              StreamBuilder<List<Canteen>>(
                stream: fs.streamApprovedCanteens(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting || _isLoadingLocation) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const SkeletonCanteenCard(),
                          childCount: 5,
                        ),
                      ),
                    );
                  }
                  
                  final venues = (snap.data ?? []).where((v) {
                    bool matchesSearch = v.name.toLowerCase().contains(_searchQuery);
                    if (!matchesSearch) return false;
                    if (_currentPosition == null) return v.type == VenueType.canteen;
                    return LocationHelper.isWithinRadius(
                      userLat: _currentPosition!.latitude,
                      userLng: _currentPosition!.longitude,
                      venueLat: v.latitude,
                      venueLng: v.longitude,
                      radiusInMeters: v.deliveryRadius,
                    );
                  }).toList();

                  if (venues.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('No venues found nearby.', style: TextStyle(color: AppColors.textLow)),
                      ),
                    );
                  }
                  
                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final canteen = venues[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: RestaurantCard(
                              canteen: canteen, 
                              userPosition: _currentPosition,
                            ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1),
                          );
                        },
                        childCount: venues.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  const _AppBarAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(icon, size: 20, color: AppColors.textHigh),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _CategoryItem({required this.label, required this.icon, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.transparent : AppColors.glassBorder),
              boxShadow: isSelected ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.black : AppColors.textMed, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textLow,
            ),
          ),
        ],
      ),
    );
  }
}
