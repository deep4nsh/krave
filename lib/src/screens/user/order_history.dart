import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'order_tracking.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        // ADDED: Explicit back button for clarity
        leading: const BackButton(),
      ),
      body: userId == null
          ? const Center(child: Text('You must be logged in to see your orders.'))
          : StreamBuilder<List<OrderModel>>(
              stream: fs.streamOrdersForUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('You haven\'t placed any orders yet.', style: TextStyle(fontSize: 18)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: ListTile(
                        title: Text('Order #${order.id.substring(0, 6)}...'),
                        subtitle: Text('Token: ${order.tokenNumber} • Status: ${order.status}'),
                        trailing: Text('₹${order.totalAmount}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderTracking(orderId: order.id)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
