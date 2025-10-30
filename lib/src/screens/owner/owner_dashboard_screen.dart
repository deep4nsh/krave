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
        
        // Calculate stats
        final pendingOrders = orders.where((o) => o.status == 'Pending').length;
        final preparingOrders = orders.where((o) => o.status == 'Preparing').length;

        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        
        final todaysOrders = orders.where((o) => o.timestamp.isAfter(startOfToday)).toList();
        final completedToday = todaysOrders.where((o) => o.status == 'Ready for Pickup' || o.status == 'Completed').length;
        final revenueToday = todaysOrders
            .where((o) => o.status == 'Ready for Pickup' || o.status == 'Completed')
            .fold(0.0, (sum, item) => sum + item.totalAmount);

        return GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16.0),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _StatCard(
              title: 'Pending Orders',
              value: pendingOrders.toString(),
              icon: Icons.hourglass_top,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'In Progress',
              value: preparingOrders.toString(),
              icon: Icons.soup_kitchen,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Completed Today',
              value: completedToday.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Revenue Today',
              value: '₹${revenueToday.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
