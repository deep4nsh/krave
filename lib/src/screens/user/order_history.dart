import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_invoice_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';
import 'package:krave/src/screens/user/order_tracking.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Your Orders'),
      ),
      body: GradientBackground(
        child: userId == null
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
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _AnimatedOrderHistoryCard(order: orders[index], index: index);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _AnimatedOrderHistoryCard extends StatefulWidget {
  final OrderModel order;
  final int index;
  const _AnimatedOrderHistoryCard({required this.order, required this.index});

  @override
  State<_AnimatedOrderHistoryCard> createState() => _AnimatedOrderHistoryCardState();
}

class _AnimatedOrderHistoryCardState extends State<_AnimatedOrderHistoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
        child: _OrderHistoryCard(order: widget.order),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderHistoryCard({required this.order});

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending': return Icons.hourglass_top_rounded;
      case 'Preparing': return Icons.soup_kitchen_rounded;
      case 'Ready for Pickup': return Icons.check_circle_rounded;
      case 'Completed': return Icons.verified_rounded;
      case 'Cancelled': return Icons.cancel_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoiceService = PdfInvoiceService();

    Color statusColor;
    switch (order.status) {
      case 'Completed': statusColor = Colors.greenAccent; break;
      case 'Cancelled': statusColor = Colors.redAccent; break;
      case 'Preparing': statusColor = Colors.orangeAccent; break;
      case 'Pending': statusColor = theme.colorScheme.primary; break;
      default: statusColor = theme.colorScheme.primary;
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 20),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.05,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Token #${order.tokenNumber}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(order.status), color: statusColor, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          order.status.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1, thickness: 1, color: Colors.white10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${order.totalAmount}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Invoice'),
                      onPressed: () => invoiceService.saveAsPdf(order),
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
