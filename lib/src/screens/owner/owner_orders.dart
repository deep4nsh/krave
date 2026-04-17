import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/krave_loading.dart';

class OwnerOrders extends StatelessWidget {
  final String canteenId;
  const OwnerOrders({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white38,
            indicatorColor: AppColors.primary,
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            tabs: const [
              Tab(text: 'NEW'),
              Tab(text: 'KITCHEN'),
              Tab(text: 'READY'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: fs.streamOrdersForCanteen(canteenId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return KraveLoading(size: 50);
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                }

                final allOrders = snapshot.data ?? [];
                
                // Categorize orders
                final pending = allOrders.where((o) => o.status == 'Pending').toList();
                final preparing = allOrders.where((o) => o.status == 'Preparing').toList();
                final ready = allOrders.where((o) => ['Ready for Pickup', 'Out for Delivery'].contains(o.status)).toList();

                return TabBarView(
                  children: [
                    _OrderQueueList(orders: pending, emptyIcon: Icons.receipt_long_rounded, emptyMsg: 'No new orders yet.'),
                    _OrderQueueList(orders: preparing, emptyIcon: Icons.restaurant_rounded, emptyMsg: 'Kitchen is quiet.'),
                    _OrderQueueList(orders: ready, emptyIcon: Icons.check_circle_outline_rounded, emptyMsg: 'No orders waiting.'),
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

class _OrderQueueList extends StatelessWidget {
  final List<OrderModel> orders;
  final IconData emptyIcon;
  final String emptyMsg;

  const _OrderQueueList({required this.orders, required this.emptyIcon, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: Colors.white12),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _VelocityOrderCard(order: order);
      },
    );
  }
}

class _VelocityOrderCard extends StatelessWidget {
  final OrderModel order;
  const _VelocityOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    
    // Efficiency Mapping
    String nextStatus = 'Preparing';
    Color stateColor = Colors.redAccent;
    IconData actionIcon = Icons.restaurant_rounded;

    if (order.status == 'Preparing') {
      nextStatus = 'Ready for Pickup';
      stateColor = Colors.blueAccent;
      actionIcon = Icons.check_circle_outline_rounded;
    } else if (order.status == 'Ready for Pickup' || order.status == 'Out for Delivery') {
      nextStatus = 'Completed';
      stateColor = const Color(0xFF10b981); // Emerald
      actionIcon = Icons.handshake_rounded;
    }

    return Dismissible(
      key: Key(order.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 32),
        decoration: BoxDecoration(color: stateColor, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 32),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        fs.updateOrderStatus(order.id, nextStatus);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: stateColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: stateColor.withOpacity(0.3), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // MASSIVE TOKEN SIDEBAR
                Container(
                  width: 100,
                  color: stateColor.withOpacity(0.2),
                  child: Center(
                    child: Text(
                      order.tokenNumber,
                      style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
                
                // ORDER DETAILS
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(order.orderType == 'dineIn' ? Icons.restaurant_rounded : Icons.delivery_dining_rounded, size: 14, color: Colors.white38),
                            const SizedBox(width: 6),
                            Text(
                              order.orderType == 'dineIn' ? 'DINE-IN' : 'DELIVERY',
                              style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...order.items.map((item) => Text(
                          '${item['quantity']}x ${item['name']}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        )),
                        const SizedBox(height: 16),
                        // Action Reminder
                        Row(
                          children: [
                            Icon(actionIcon, size: 16, color: stateColor),
                            const SizedBox(width: 8),
                            Text(
                              'SWIPE TO ADVANCE',
                              style: TextStyle(color: stateColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
