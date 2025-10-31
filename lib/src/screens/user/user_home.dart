import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import 'canteen_menu.dart';
import '../auth/login_screen.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  Future<void> _logout(BuildContext context) async {
    // FIX: Capture navigator and messenger before the async gap.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    
    try {
      await auth.logout();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krave - Canteens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Canteen>>(
        stream: fs.streamApprovedCanteens(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final canteens = snap.data ?? [];
          if (canteens.isEmpty) {
            return const Center(child: Text('No approved canteens available right now.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: canteens.length,
            itemBuilder: (context, i) {
              return CanteenCard(canteen: canteens[i]);
            },
          );
        },
      ),
    );
  }
}

class CanteenCard extends StatelessWidget {
  final Canteen canteen;
  const CanteenCard({super.key, required this.canteen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final hasTimings = canteen.openingTime != null && canteen.closingTime != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CanteenMenu(canteen: canteen)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(canteen.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (hasTimings)
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${canteen.openingTime} - ${canteen.closingTime}', style: timeStyle),
                  ],
                )
              else
                Text('Timings not available', style: timeStyle),
            ],
          ),
        ),
      ),
    );
  }
}
