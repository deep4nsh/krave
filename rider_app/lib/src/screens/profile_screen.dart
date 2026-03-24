import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rider = auth.rider;

    if (rider == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Avatar / header
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    rider.name.isNotEmpty ? rider.name[0].toUpperCase() : 'R',
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(rider.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(rider.email,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Status card
        _StatusCard(isActive: rider.isActive, onToggle: auth.toggleActive),
        const SizedBox(height: 16),

        // Info tiles
        _ProfileTile(
          icon: Icons.phone_rounded,
          label: 'Phone',
          value: rider.phone.isEmpty ? 'Not set' : rider.phone,
        ),
        _ProfileTile(
          icon: Icons.email_rounded,
          label: 'Email',
          value: rider.email,
        ),
        _ProfileTile(
          icon: Icons.badge_rounded,
          label: 'Rider ID',
          value: '${rider.id.substring(0, 10)}…',
          mono: true,
        ),
        const SizedBox(height: 32),

        // Sign out
        OutlinedButton.icon(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRed),
          label: const Text('Sign Out',
              style: TextStyle(
                  color: AppTheme.accentRed, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: AppTheme.accentRed.withOpacity(0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text('Sign Out'),
                content:
                    const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: AppTheme.accentRed))),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthProvider>().signOut();
            }
          },
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _StatusCard({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accentGreen.withOpacity(0.08)
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.accentGreen.withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: isActive ? AppTheme.accentGreen : AppTheme.textMuted,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? 'You\'re Online' : 'You\'re Offline',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isActive ? AppTheme.accentGreen : AppTheme.textMuted,
                ),
              ),
              Text(
                isActive ? 'Receiving orders' : 'Not receiving orders',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Switch.adaptive(
            value: isActive,
            onChanged: onToggle,
            activeTrackColor: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
