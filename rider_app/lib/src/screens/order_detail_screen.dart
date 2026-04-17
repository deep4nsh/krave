import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krave/src/models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  static const _statusFlow = [
    'Pending',
    'Preparing',
    'Ready for Pickup',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final auth = context.read<AuthProvider>();

    // Find order from the combined active + all lists
    final all = [...orderProv.activeOrders, ...orderProv.allOrders];
    final order = all.cast<OrderModel?>().firstWhere(
          (o) => o?.id == orderId,
          orElse: () => null,
        );

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final canteen = orderProv.canteenName(order.canteenId);
    final currentIdx = _statusFlow.indexOf(order.status);
    final canAdvance = currentIdx >= 0 && currentIdx < _statusFlow.length - 1;
    final nextStatus = canAdvance ? _statusFlow[currentIdx + 1] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Token: ${order.tokenNumber}'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            _StatusStepper(currentStatus: order.status),
            const SizedBox(height: 20),

            // Canteen info card
            _InfoCard(
              icon: Icons.storefront_rounded,
              iconColor: AppTheme.accentBlue,
              title: 'Canteen',
              value: canteen,
            ),
            const SizedBox(height: 12),

            // Token info
            _InfoCard(
              icon: Icons.confirmation_number_rounded,
              iconColor: AppTheme.accent,
              title: 'Token Number',
              value: order.tokenNumber,
              mono: true,
            ),
            const SizedBox(height: 12),

            // Amount
            _InfoCard(
              icon: Icons.currency_rupee_rounded,
              iconColor: AppTheme.accentGreen,
              title: 'Total Amount',
              value: '₹${order.totalAmount}',
            ),
            const SizedBox(height: 12),

            // Time
            _InfoCard(
              icon: Icons.access_time_rounded,
              iconColor: AppTheme.textSecondary,
              title: 'Order Time',
              value: DateFormat('d MMM, h:mm a').format(order.createdAt),
            ),
            const SizedBox(height: 20),

            // Items list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Ordered',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${item['quantity'] ?? 1}',
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['name'] ?? '—',
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 14),
                              ),
                            ),
                            Text(
                              '₹${item['price'] ?? 0}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action button
            if (nextStatus != null && !order.isDone)
              ElevatedButton.icon(
                icon: Icon(_nextIcon(nextStatus)),
                label: Text('Mark as "$nextStatus"'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nextColor(nextStatus),
                  foregroundColor: Colors.white,
                ),
                onPressed: orderProv.loading
                    ? null
                    : () async {
                        await orderProv.updateStatus(
                          order.id,
                          nextStatus,
                          auth.rider?.id ?? '',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Updated to "$nextStatus"'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                          if (nextStatus == 'Completed') {
                            Navigator.pop(context);
                          }
                        }
                      },
              ),

            if (order.isDone)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Order completed',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _nextColor(String status) {
    switch (status) {
      case 'Preparing':
        return AppTheme.accentBlue;
      case 'Ready for Pickup':
        return AppTheme.accentGreen;
      case 'Completed':
        return AppTheme.textSecondary;
      default:
        return AppTheme.accent;
    }
  }

  IconData _nextIcon(String status) {
    switch (status) {
      case 'Preparing':
        return Icons.restaurant_rounded;
      case 'Ready for Pickup':
        return Icons.check_circle_rounded;
      case 'Completed':
        return Icons.done_all_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }
}

class _StatusStepper extends StatelessWidget {
  final String currentStatus;
  const _StatusStepper({required this.currentStatus});

  static const _steps = ['Pending', 'Preparing', 'Ready for Pickup', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIdx < currentIdx
                    ? AppTheme.accentGreen
                    : AppTheme.border,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isDone = stepIdx <= currentIdx;
          final isCurrent = stepIdx == currentIdx;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.accentGreen
                      : AppTheme.surfaceVariant,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: AppTheme.accentGreen, width: 2)
                      : null,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : Icons.circle_outlined,
                  size: 14,
                  color: isDone ? Colors.white : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[stepIdx].split(' ').first,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color:
                      isCurrent ? AppTheme.accentGreen : AppTheme.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool mono;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
