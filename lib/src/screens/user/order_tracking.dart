import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';

class OrderTracking extends StatelessWidget {
  final String orderId;
  const OrderTracking({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
      ),
      body: StreamBuilder<OrderModel>(
        stream: fs.streamOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load order details.'));
          }

          final order = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTokenCard(context, order.tokenNumber),
              const SizedBox(height: 24),
              _buildStatusTracker(context, order.status),
              const SizedBox(height: 24),
              _buildOrderSummary(context, order),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTokenCard(BuildContext context, String tokenNumber) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'YOUR TOKEN NUMBER',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              tokenNumber,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTracker(BuildContext context, String currentStatus) {
    const statuses = ['Pending', 'Preparing', 'Ready for Pickup'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(statuses.length, (index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            return _StatusNode(
              title: statuses[index],
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Order', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ...order.items.map((item) => ListTile(
                    title: Text(item['name'] ?? 'N/A'),
                    subtitle: Text('Qty: ${item['quantity'] ?? item['qty']}'),
                    trailing: Text('₹${item['price']}'),
                  )),
              const Divider(height: 1),
              ListTile(
                title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  '₹${order.totalAmount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusNode extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isCurrent;

  const _StatusNode({required this.title, required this.isCompleted, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey;
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
