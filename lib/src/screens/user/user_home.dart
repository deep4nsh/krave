import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import '../../widgets/gradient_background.dart';
import 'canteen_menu.dart';
import '../auth/login_screen.dart';
import 'order_history.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthService>();
    try {
      await auth.logout();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krave'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Order History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: StreamBuilder<List<Canteen>>(
          stream: fs.streamApprovedCanteens(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final canteens = snap.data ?? [];
            if (canteens.isEmpty) {
              return const Center(child: Text('No approved canteens available right now.'));
            }
            // Use ListView.separated for better spacing and animations
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: canteens.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                // Wrap card in an animation widget
                return _AnimatedCanteenCard(canteen: canteens[i], index: i);
              },
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCanteenCard extends StatefulWidget {
  final Canteen canteen;
  final int index;

  const _AnimatedCanteenCard({required this.canteen, required this.index});

  @override
  State<_AnimatedCanteenCard> createState() => _AnimatedCanteenCardState();
}

class _AnimatedCanteenCardState extends State<_AnimatedCanteenCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Stagger the animation based on the item's index
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CanteenCard(canteen: widget.canteen),
      ),
    );
  }
}

class CanteenCard extends StatelessWidget {
  final Canteen canteen;
  const CanteenCard({super.key, required this.canteen});

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
      builder: (context) => AlertDialog(
        title: const Text('Edit Canteen Timings'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().currentUser;
    final isOwner = user?.uid == canteen.ownerId;
    final hasTimings = canteen.openingTime != null && canteen.closingTime != null;

    return Card(
      // The new CardTheme from main.dart is applied automatically
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CanteenMenu(canteen: canteen)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(canteen.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: isOwner ? () => _showEditTimingsDialog(context) : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time, 
                            size: 18, 
                            color: isOwner ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant
                          ),
                          const SizedBox(width: 8),
                          if (hasTimings)
                            Text(
                              '${canteen.openingTime} - ${canteen.closingTime}', 
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOwner ? theme.colorScheme.primary : null,
                                decoration: isOwner ? TextDecoration.underline : null,
                              )
                            )
                          else
                            Text(
                              'Set Timings', 
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOwner ? theme.colorScheme.primary : null,
                                fontStyle: FontStyle.italic
                              )
                            ),
                          if (isOwner) ...[
                             const SizedBox(width: 4),
                             Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
