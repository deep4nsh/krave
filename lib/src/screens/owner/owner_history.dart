import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';

class OwnerHistory extends StatelessWidget {
  final String canteenId;
  const OwnerHistory({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return StreamBuilder<List<OrderModel>>(
      stream: fs.streamOrdersForCanteen(canteenId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final completedOrders = snap.data!.where((o) => o.status == 'Completed').toList();
        if (completedOrders.isEmpty) return const Center(child: Text('No completed orders.'));
        return ListView.builder(
          itemCount: completedOrders.length,
          itemBuilder: (context, i) {
            final o = completedOrders[i];
            return ListTile(
              title: Text('Token: ${o.tokenNumber}'),
              subtitle: Text('₹${o.totalAmount} - ${o.items.map((e) => e['name']).join(', ')}'),
            );
          },
        );
      },
    );
  }
}