import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_background.dart';
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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: GradientBackground(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_canteenId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const GradientBackground(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Your account has not been assigned a canteen yet. Please contact the administrator.',
                textAlign: TextAlign.center,
              ),
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
      extendBody: true, // Make body extend behind the bottom nav bar
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout)],
      ),
      body: GradientBackground(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: pages,
        ),
      ),
      bottomNavigationBar: _KraveBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}

class _KraveBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _KraveBottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.secondary,
        showUnselectedLabels: false,
        showSelectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
        ],
      ),
    );
  }
}
