import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import 'package:krave/src/models/order_model.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Today';
  final _filters = ['Today', 'This Week', 'All'];

  bool _matchesFilter(OrderModel o) {
    final now = DateTime.now();
    switch (_filter) {
      case 'Today':
        return o.timestamp.year == now.year &&
            o.timestamp.month == now.month &&
            o.timestamp.day == now.day;
      case 'This Week':
        return now.difference(o.timestamp).inDays <= 7;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final filtered =
        orders.allOrders.where(_matchesFilter).toList();

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _filters
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppTheme.accent.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _filter == f
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          fontWeight: _filter == f
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: _filter == f
                              ? AppTheme.accent.withOpacity(0.4)
                              : AppTheme.border,
                        ),
                        backgroundColor: AppTheme.surfaceVariant,
                        showCheckmark: false,
                      ),
                    ))
                .toList(),
          ),
        ),

        // Count summary
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} orders',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${filtered.where((o) => o.status == 'Completed' || o.status == 'Ready for Pickup').fold(0, (s, o) => s + o.totalAmount)} revenue',
                  style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        if (filtered.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No orders in this period',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final o = filtered[i];
                return OrderCard(
                  order: o,
                  canteenName: orders.canteenName(o.canteenId),
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: o.id)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
