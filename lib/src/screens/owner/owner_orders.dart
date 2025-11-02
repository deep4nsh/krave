import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class OwnerOrders extends StatelessWidget {
  final String canteenId;
  const OwnerOrders({super.key, required this.canteenId});

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

        final allOrders = snapshot.data ?? [];
        final pendingOrders = allOrders.where((o) => o.status == 'Pending').toList();
        final preparingOrders = allOrders.where((o) => o.status == 'Preparing').toList();

        if (pendingOrders.isEmpty && preparingOrders.isEmpty) {
          return const Center(
            child: Text('No active orders right now.', style: TextStyle(fontSize: 18)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            if (pendingOrders.isNotEmpty)
              _OrderSection(title: 'New Orders', orders: pendingOrders),
            if (preparingOrders.isNotEmpty)
              _OrderSection(title: 'In Progress', orders: preparingOrders),
          ],
        );
      },
    );
  }
}

class _OrderSection extends StatelessWidget {
  final String title;
  final List<OrderModel> orders;

  const _OrderSection({required this.title, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        ...orders.map((order) => _OrderCard(order: order)),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  String get _nextStatus {
    if (order.status == 'Pending') return 'Preparing';
    if (order.status == 'Preparing') return 'Ready for Pickup';
    return 'Completed'; // Should not happen on this screen
  }

  String get _actionText {
    if (order.status == 'Pending') return 'Start Preparing';
    if (order.status == 'Preparing') return 'Mark as Ready';
    return 'Complete';
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Token: ${order.tokenNumber}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(DateFormat.jm().format(order.timestamp), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items.map((item) {
                  return Text('${item['quantity'] ?? item['qty']} x ${item['name']}');
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  fs.updateOrderStatus(order.id, _nextStatus);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: order.status == 'Pending' ? Colors.blueAccent : Colors.green,
                ),
                child: Text(_actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
