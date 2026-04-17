import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/order_model.dart';
import '../../models/rider_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/krave_loading.dart';
import '../../theme/app_colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Track Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textHigh)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHigh, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: fs.streamOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return KraveLoading(size: 60);
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Could not load order details.', style: TextStyle(color: AppColors.textLow)));
          }

          final order = snapshot.data!;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: _OrderSuccessHeader(order: order).animate().fadeIn().scale(curve: Curves.easeOutBack),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _StatusTimeline(currentStatus: order.status, orderType: order.orderType),
                ),
              ),
              if (order.riderId != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _RiderCard(riderId: order.riderId!, fs: fs),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: _OrderSummaryCard(order: order),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderSuccessHeader extends StatelessWidget {
  final OrderModel order;
  const _OrderSuccessHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORDER TOKEN', style: TextStyle(color: AppColors.textLow, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(
                    order.tokenNumber,
                    style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: order.id,
                  version: QrVersions.auto,
                  size: 80.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: AppColors.glassBorder),
          Row(
            children: [
              Icon(
                order.orderType == 'dineIn' ? Icons.restaurant_rounded : Icons.delivery_dining_rounded,
                color: AppColors.textMed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                order.orderType == 'dineIn' ? 'Dine-in at Canteen' : 'Delivery to your spot',
                style: const TextStyle(color: AppColors.textMed, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final String orderType;

  const _StatusTimeline({required this.currentStatus, required this.orderType});

  @override
  Widget build(BuildContext context) {
    final statuses = orderType == 'delivery' 
        ? ['Pending', 'Preparing', 'Out for Delivery', 'Completed']
        : ['Pending', 'Preparing', 'Ready for Pickup', 'Completed'];
    
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Tracking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHigh),
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
                        color: isCompleted ? AppColors.primary : AppColors.surface,
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : Border.all(color: AppColors.glassBorder),
                      ),
                      child: isCompleted && !isCurrent
                          ? const Icon(Icons.check, size: 14, color: Colors.black)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < currentIndex ? AppColors.primary : AppColors.glassBorder,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted ? AppColors.textHigh : AppColors.textLow,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getStatusDesc(statuses[index]),
                            style: const TextStyle(color: AppColors.primary, fontSize: 13),
                          ).animate().fadeIn().slideX(begin: -0.1),
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

  String _getStatusDesc(String status) {
    switch (status) {
      case 'Pending': return 'We\'ve got your order! Notifying the chef...';
      case 'Preparing': return 'Your fuel is being prepared by the pros.';
      case 'Out for Delivery': return 'The rider is zooming to your location!';
      case 'Ready for Pickup': return 'Hot and fresh! Grab it from the counter.';
      case 'Completed': return 'Order complete. High-five?';
      default: return 'Processing...';
    }
  }
}

class _RiderCard extends StatelessWidget {
  final String riderId;
  final FirestoreService fs;

  const _RiderCard({required this.riderId, required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RiderModel?>(
      stream: fs.streamRider(riderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final rider = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                radius: 24,
                child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR RIDER', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(rider.name, style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHigh)),
          const SizedBox(height: 20),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item['quantity']}x ${item['name']}', style: const TextStyle(color: AppColors.textMed)),
                Text('₹${item['price']}', style: const TextStyle(color: AppColors.textHigh, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          const Divider(height: 32, color: AppColors.glassBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHigh)),
              Text('₹${order.totalAmount}', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
