import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _svc;

  OrderProvider(this._svc);

  List<OrderModel> _activeOrders = [];
  List<OrderModel> _allOrders = [];
  bool _loading = false;
  String? _error;

  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get allOrders => _allOrders;
  bool get loading => _loading;
  String? get error => _error;

  // Cache canteen names (canteenId → name)
  final Map<String, String> _canteenCache = {};

  void listenActiveOrders() {
    _svc.streamActiveOrders().listen((orders) {
      _activeOrders = orders;
      _prefetchCanteens(orders);
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  void listenAllOrders() {
    _svc.streamAllOrders().listen((orders) {
      _allOrders = orders;
      _prefetchCanteens(orders);
      notifyListeners();
    });
  }

  Future<void> _prefetchCanteens(List<OrderModel> orders) async {
    final ids = orders.map((o) => o.canteenId).toSet();
    for (final id in ids) {
      if (!_canteenCache.containsKey(id)) {
        _canteenCache[id] = await _svc.getCanteenName(id);
      }
    }
    notifyListeners();
  }

  String canteenName(String id) => _canteenCache[id] ?? 'Canteen';

  Future<void> updateStatus(
      String orderId, String newStatus, String riderId) async {
    _loading = true;
    notifyListeners();
    try {
      await _svc.updateOrderStatus(orderId, newStatus, riderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
