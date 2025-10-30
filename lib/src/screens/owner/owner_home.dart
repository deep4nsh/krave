import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'owner_dashboard_screen.dart';
import 'owner_orders.dart';
import 'manage_menu.dart';
import 'owner_history.dart';
import '../auth/login_screen.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  int _selectedIndex = 0;
  String? _canteenId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    if (auth.currentUser == null) return;

    final ownerDoc = await fs.getOwnerDoc(auth.currentUser!.uid);
    if (mounted) {
      setState(() {
        _canteenId = ownerDoc?['canteen_id'];
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    await auth.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_canteenId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your account has not been assigned a canteen yet. Please contact the administrator.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final List<Widget> pages = [
      OwnerDashboardScreen(canteenId: _canteenId!),
      OwnerOrders(canteenId: _canteenId!),
      ManageMenu(canteenId: _canteenId!),
      OwnerHistory(canteenId: _canteenId!),
    ];

    final List<String> pageTitles = ['Dashboard', 'Live Orders', 'Manage Menu', 'Order History'];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
