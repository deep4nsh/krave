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

    return DefaultTabController(
      length: 2, // Two tabs: New and In Progress
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'NEW'),
              Tab(text: 'IN PROGRESS'),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
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

                return TabBarView(
                  children: [
                    _OrderList(orders: pendingOrders, emptyMessage: 'No new orders right now.'),
                    _OrderList(orders: preparingOrders, emptyMessage: 'No orders are being prepared.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyMessage;

  const _OrderList({required this.orders, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyLarge));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) => _AnimatedOrderCard(order: orders[index], index: index),
    );
  }
}

class _AnimatedOrderCard extends StatefulWidget {
  final OrderModel order;
  final int index;

  const _AnimatedOrderCard({required this.order, required this.index});

  @override
  State<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<_AnimatedOrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
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
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_animation),
        child: _OrderCard(order: widget.order),
      ),
    );
  }
}


class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  String get _nextStatus => (order.status == 'Pending') ? 'Preparing' : 'Ready for Pickup';
  String get _actionText => (order.status == 'Pending') ? 'Start Preparing' : 'Mark as Ready';
  Color get _actionColor => (order.status == 'Pending') ? Colors.blueAccent : Colors.green;

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token Number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                  ),
                  child: Text(
                    '#${order.tokenNumber}',
                    style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                // Timestamp
                Text(DateFormat.jm().format(order.timestamp), style: theme.textTheme.bodyMedium),
              ],
            ),
            const Divider(height: 24),
            // Item List
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Text('${item['quantity'] ?? item['qty']}x', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item['name'], style: theme.textTheme.bodyLarge)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  fs.updateOrderStatus(order.id, _nextStatus);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _actionColor),
                child: Text(_actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
