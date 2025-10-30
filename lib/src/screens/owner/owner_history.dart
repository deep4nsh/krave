import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class OwnerHistory extends StatelessWidget {
  final String canteenId;
  const OwnerHistory({super.key, required this.canteenId});

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
        // History includes all orders that are no longer in an active state.
        final pastOrders = allOrders
            .where((o) => o.status != 'Pending' && o.status != 'Preparing')
            .toList();

        if (pastOrders.isEmpty) {
          return const Center(
            child: Text('No completed orders yet.', style: TextStyle(fontSize: 18)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: pastOrders.length,
          itemBuilder: (context, index) {
            final order = pastOrders[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                title: Text(
                  'Token: ${order.tokenNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Status: ${order.status}\n${DateFormat.yMMMd().add_jm().format(order.timestamp)}',
                ),
                trailing: Text(
                  '₹${order.totalAmount}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
