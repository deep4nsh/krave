import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class WatchdogService {
  static final WatchdogService _instance = WatchdogService._internal();
  factory WatchdogService() => _instance;
  WatchdogService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications = NotificationService();
  
  StreamSubscription? _orderSub;
  final Map<String, String> _lastStatusMap = {};

  void start(String userId) {
    if (_orderSub != null) return;

    print('--- Starting Master Watchdog for $userId ---');
    
    // Listen to all active orders for the user
    _orderSub = _db.collection('Orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereNotIn: ['Completed', 'Cancelled'])
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final orderId = change.doc.id;
        final status = data['status'] as String? ?? 'Pending';
        final token = data['tokenNumber'] as String? ?? 'Unknown';

        // Check if status has changed
        if (_lastStatusMap.containsKey(orderId)) {
          final oldStatus = _lastStatusMap[orderId];
          if (oldStatus != status) {
            _triggerNotification(token, status);
          }
        }
        
        // Update local status map
        _lastStatusMap[orderId] = status;
        
        // Cleanup if order finished (though query might handle it)
        if (status == 'Completed' || status == 'Cancelled') {
          _lastStatusMap.remove(orderId);
        }
      }
    });

    // Also listen to wallet transfers (Credit transactions)
    _db.collection('Transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'credit')
        .where('timestamp', isGreaterThan: Timestamp.now()) // Only new ones
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final amount = data['amount'] ?? 0;
          _notifications.showInstantNotification(
            title: 'You got a Treat! 💸',
            body: 'Someone just sent you ₹$amount in your Krave wallet.',
          );
        }
      }
    });
  }

  void stop() {
    print('--- Stopping Master Watchdog ---');
    _orderSub?.cancel();
    _orderSub = null;
    _lastStatusMap.clear();
  }

  void _triggerNotification(String token, String status) {
    final body = _getFunkyMessage(status);
    _notifications.showInstantNotification(
      title: 'Krave Update! 🍔',
      body: body,
      payload: 'order_update',
    );
  }

  String _getFunkyMessage(String status) {
    switch (status) {
      case 'Preparing': return 'Chef is speed-running your order! 👨‍🍳';
      case 'Ready for Pickup': return 'Tokens Up! Your meal is waiting at the counter! 🍔';
      case 'Out for Delivery': return 'The Rider is zooming to your spot! 🛵';
      case 'Completed': return 'Order complete. Hope you enjoyed the treat! 🙌';
      case 'Cancelled': return 'Order cancelled. Refund initiated to your wallet. 💸';
      default: return 'Your order status is now: $status';
    }
  }
}
