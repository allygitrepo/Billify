import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SectionCard(
              title: 'Appearance',
              child: Column(
                children: [
                  _ThemeOption(
                    label: 'Light Mode',
                    icon: Icons.light_mode_outlined,
                    isSelected: themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    label: 'Dark Mode',
                    icon: Icons.dark_mode_outlined,
                    isSelected: themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                  ),
                  const Divider(height: 1),
                  _ThemeOption(
                    label: 'System Default',
                    icon: Icons.settings_brightness_outlined,
                    isSelected: themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Account & Data',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () => _showLogoutDialog(context, ref),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.grey),
                    title: const Text('Reset All Data'),
                    subtitle: const Text('Clear all user and business information'),
                    onTap: () => _showResetDialog(context, ref),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Billify v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete ALL user and business information. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              await ref.read(businessProvider.notifier).clearAll();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryTeal : Colors.grey),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryTeal)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
