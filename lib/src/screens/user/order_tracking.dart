import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_container.dart';

class OrderTracking extends StatelessWidget {
  final String orderId;
  const OrderTracking({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Track Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: StreamBuilder<OrderModel>(
          stream: fs.streamOrder(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Could not load order details.'));
            }

            final order = snapshot.data!;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 120, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: _buildTokenSection(context, order.tokenNumber),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatusTimeline(context, order.status),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: _buildOrderDetails(context, order),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTokenSection(BuildContext context, String tokenNumber) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 32),
      borderRadius: BorderRadius.circular(32),
      color: theme.colorScheme.primary,
      opacity: 0.9,
      child: Column(
        children: [
          Text(
            'YOUR TOKEN',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tokenNumber,
            style: GoogleFonts.outfit(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Show this at the counter',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context, String currentStatus) {
    final theme = Theme.of(context);
    const statuses = ['Pending', 'Preparing', 'Ready for Pickup', 'Completed'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Updates',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...List.generate(statuses.length, (index) {
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == statuses.length - 1;

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.1),
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: isCurrent ? [
                          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                        ] : null,
                      ),
                      child: isCompleted && !isCurrent
                          ? const Icon(Icons.check, size: 14, color: Colors.black)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < currentIndex ? theme.colorScheme.primary : Colors.white10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statuses[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted ? Colors.white : Colors.white24,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getStatusDescription(statuses[index]),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary.withOpacity(0.8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Pending': return 'We\'ve received your order and notifying the chef.';
      case 'Preparing': return 'Your meal is being prepared with care.';
      case 'Ready for Pickup': return 'Hot and fresh! Please collect your order.';
      case 'Completed': return 'Hope you enjoyed your meal!';
      default: return 'Processing...';
    }
  }

  Widget _buildOrderDetails(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item['quantity'] ?? item['qty']}x ${item['name']}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                Text('₹${item['price']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '₹${order.totalAmount}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
