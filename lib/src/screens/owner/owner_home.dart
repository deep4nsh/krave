import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/image_search_service.dart';
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

  // Step 1: The dialog logic is now here, in the parent Scaffold
  void _addMenuItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSaving) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      const Text('Searching for image and saving...'),
                    ] else ...[
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                      TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                      TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
                    ]
                  ],
                ),
              ),
              actions: isSaving ? [] : [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final fs = context.read<FirestoreService>();
                    final imageSearch = context.read<ImageSearchService>();
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final name = nameCtrl.text.trim();
                    final priceText = priceCtrl.text.trim();
                    final category = categoryCtrl.text.trim();

                    if (name.isEmpty || priceText.isEmpty || category.isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('All fields are required.')));
                      return;
                    }
                    final parsedPrice = int.tryParse(priceText);
                    if (parsedPrice == null) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter a valid price.')));
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      final imageUrl = await imageSearch.searchImage(name);
                      await fs.addMenuItem(_canteenId!, {
                        'name': name,
                        'price': parsedPrice,
                        'category': category,
                        'available': true,
                        'photoUrl': imageUrl,
                      });
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
                      setDialogState(() => isSaving = false);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
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
      extendBody: true,
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
      // Step 2: The FAB is now here and shown conditionally
      floatingActionButton: _selectedIndex == 2 
          ? FloatingActionButton.extended(
              onPressed: _addMenuItemDialog,
              label: const Text('ADD ITEM'),
              icon: const Icon(Icons.add),
            )
          : null,
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
