import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';

class OwnerOrders extends StatelessWidget {
  final String canteenId;
  const OwnerOrders({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return StreamBuilder<List<OrderModel>>(
      stream: fs.streamOrdersForCanteen(canteenId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!;
        if (orders.isEmpty) return const Center(child: Text('No active orders.'));
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Token: ${o.tokenNumber} • ₹${o.totalAmount}'),
                subtitle: Text('Status: ${o.status}\nItems: ${o.items.map((e) => e['name']).join(', ')}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => fs.updateOrderStatus(o.id, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Pending', child: Text('Pending')),
                    PopupMenuItem(value: 'Ready', child: Text('Ready')),
                    PopupMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}