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
                  return const KraveLoading(size: 50);
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: orders.length,
      itemBuilder: (context, index) => _KitchenOrderCard(order: orders[index]).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final OrderModel order;
  const _KitchenOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    
    // Determine next step
    String nextStatus = 'Preparing';
    String actionLabel = 'START COOKING';
    Color actionColor = AppColors.primary;

    if (order.status == 'Preparing') {
      nextStatus = (order.orderType == 'dineIn') ? 'Ready for Pickup' : 'Ready for Pickup'; // Logic currently assumes all stay ready until handoff
      actionLabel = 'MARK AS READY';
      actionColor = Colors.blueAccent;
    } else if (['Ready for Pickup', 'Out for Delivery'].contains(order.status)) {
      nextStatus = 'Completed';
      actionLabel = 'CONFIRM HAND-OFF';
      actionColor = Colors.indigoAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        opacity: 0.05,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOKEN', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    Text('#${order.tokenNumber}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.black, color: Colors.white)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat.jm().format(order.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.orderType == 'dineIn' ? Colors.orangeAccent.withOpacity(0.1) : Colors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.orderType == 'dineIn' ? 'DINE-IN' : 'DELIVERY',
                        style: TextStyle(
                          color: order.orderType == 'dineIn' ? Colors.orangeAccent : Colors.cyanAccent,
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            
            // Item List
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text('${item['quantity']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Progress Button
            if (order.status != 'Completed' && order.status != 'Cancelled')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    fs.updateOrderStatus(order.id, nextStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: actionColor == AppColors.primary ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
