import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class OwnerDashboardScreen extends StatelessWidget {
  final String canteenId;
  const OwnerDashboardScreen({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return StreamBuilder<List<OrderModel>>(
      stream: fs.streamOrdersForCanteen(canteenId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        
        // --- Calculate Stats ---
        final pendingOrders = orders.where((o) => o.status == 'Pending').length;
        final preparingOrders = orders.where((o) => o.status == 'Preparing').length;

        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        
        final todaysOrders = orders.where((o) => o.timestamp.isAfter(startOfToday)).toList();
        final completedToday = todaysOrders.where((o) => o.status == 'Ready for Pickup' || o.status == 'Completed').length;
        final revenueToday = todaysOrders
            .where((o) => o.status == 'Ready for Pickup' || o.status == 'Completed')
            .fold(0.0, (sum, item) => sum + item.totalAmount);
            
        final List<Map<String, dynamic>> stats = [
          {'title': 'Pending Orders', 'value': pendingOrders.toString(), 'icon': Icons.hourglass_top_rounded},
          {'title': 'In Progress', 'value': preparingOrders.toString(), 'icon': Icons.soup_kitchen_rounded},
          {'title': 'Completed Today', 'value': completedToday.toString(), 'icon': Icons.check_circle_rounded},
          {'title': 'Revenue Today', 'value': 'Rs. ${revenueToday.toStringAsFixed(0)}', 'icon': Icons.monetization_on_rounded},
        ];

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: stats.length + 1, // Add one for the time picker card
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == stats.length) {
              return _TimePickerCard(canteenId: canteenId);
            }
            final stat = stats[index];
            return _AnimatedStatCard(
              index: index,
              title: stat['title'],
              value: stat['value'],
              icon: stat['icon'],
            );
          },
        );
      },
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final int index;
  final String title;
  final String value;
  final IconData icon;

  const _AnimatedStatCard({
    required this.index,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
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
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(_animation),
        child: _StatCard(title: widget.title, value: widget.value, icon: widget.icon),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final String canteenId;
  const _TimePickerCard({required this.canteenId});

  Future<void> _showEditTimingsDialog(BuildContext context) async {
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Canteen Timings', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Opening Time', style: TextStyle(color: Colors.white)),
                trailing: Text(openingTime?.format(context) ?? 'Select', style: const TextStyle(color: Colors.white70)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                  if (time != null) setState(() => openingTime = time);
                },
              ),
              ListTile(
                title: const Text('Closing Time', style: TextStyle(color: Colors.white)),
                trailing: Text(closingTime?.format(context) ?? 'Select', style: const TextStyle(color: Colors.white70)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
                  if (time != null) setState(() => closingTime = time);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (openingTime != null && closingTime != null) {
                await context.read<FirestoreService>().updateCanteenTimings(
                  canteenId,
                  openingTime!.format(context),
                  closingTime!.format(context),
                );
                if (context.mounted) Navigator.pop(context);
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
    return Card(
      child: InkWell(
        onTap: () => _showEditTimingsDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(Icons.access_time_filled_rounded, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manage Timings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Tap to set opening & closing hours', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
