import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/providers/theme_provider.dart';
import 'package:billify_application/providers/feature_settings_provider.dart';
import 'package:billify_application/data/models/user_permission.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SectionCard(
              title: 'Account',
              child: ListTile(
                title: const Text('My Profile'),
                subtitle: const Text('View and update your personal details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Appearance',
              child: ListTile(
                leading: _ThemeIcon(themeMode: themeMode),
                title: const Text('Theme'),
                subtitle: Text(_themeModeLabel(themeMode)),

                onTap: () {
                  final next = switch (themeMode) {
                    ThemeMode.light => ThemeMode.dark,
                    ThemeMode.dark => ThemeMode.system,
                    ThemeMode.system => ThemeMode.light,
                  };
                  ref.read(themeProvider.notifier).setTheme(next);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (ref
                    .watch(authProvider)
                    .hasPermission(
                      PermissionModule.systemSettings,
                      PermissionAction.all,
                    ) &&
                (ref
                        .watch(authProvider)
                        .hasPermission(
                          PermissionModule.categories,
                          PermissionAction.all,
                        ) ||
                    ref
                        .watch(authProvider)
                        .hasPermission(
                          PermissionModule.products,
                          PermissionAction.all,
                        )))
              const SizedBox(height: 24),
            if (ref
                    .watch(authProvider)
                    .hasPermission(
                      PermissionModule.systemSettings,
                      PermissionAction.all,
                    ) &&
                (ref
                        .watch(authProvider)
                        .hasPermission(
                          PermissionModule.categories,
                          PermissionAction.all,
                        ) ||
                    ref
                        .watch(authProvider)
                        .hasPermission(
                          PermissionModule.products,
                          PermissionAction.all,
                        )))
              SectionCard(
                title: 'Feature Configuration',
                child: Column(
                  children: [
                    if (ref
                        .watch(authProvider)
                        .hasPermission(
                          PermissionModule.categories,
                          PermissionAction.all,
                        ))
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.category_outlined,
                          color: AppTheme.primaryTeal,
                        ),
                        title: const Text('Enable Categories'),
                        subtitle: const Text(
                          'Organize products into categories',
                        ),
                        activeColor: AppTheme.primaryTeal,
                        value: ref
                            .watch(featureSettingsProvider)
                            .isCategoryEnabled,
                        onChanged: (val) => ref
                            .read(featureSettingsProvider.notifier)
                            .updateCategoryEnabled(val),
                      ),
                    if (ref
                            .watch(authProvider)
                            .hasPermission(
                              PermissionModule.categories,
                              PermissionAction.all,
                            ) &&
                        ref
                            .watch(authProvider)
                            .hasPermission(
                              PermissionModule.products,
                              PermissionAction.all,
                            ))
                      const Divider(height: 1),
                    if (ref
                        .watch(authProvider)
                        .hasPermission(
                          PermissionModule.products,
                          PermissionAction.all,
                        ))
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.layers_outlined,
                          color: AppTheme.primaryTeal,
                        ),
                        title: const Text('Enable Product Variants'),
                        subtitle: const Text(
                          'Add multiple sizes, colors, etc. for products',
                        ),
                        activeColor: AppTheme.primaryTeal,
                        value: ref
                            .watch(featureSettingsProvider)
                            .isVariantsEnabled,
                        onChanged: (val) => ref
                            .read(featureSettingsProvider.notifier)
                            .updateVariantsEnabled(val),
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
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _showLogoutDialog(context, ref),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light mode',
    ThemeMode.dark => 'Dark mode',
    ThemeMode.system => 'System default',
  };
}

class _ThemeIcon extends StatelessWidget {
  final ThemeMode themeMode;
  const _ThemeIcon({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (themeMode) {
      ThemeMode.light => (Icons.light_mode_rounded, Colors.amber),
      ThemeMode.dark => (Icons.dark_mode_rounded, Colors.indigo),
      ThemeMode.system => (Icons.brightness_auto_rounded, AppTheme.primaryTeal),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Icon(icon, key: ValueKey(themeMode), color: color, size: 26),
    );
  }
}

class _ThemeSegmentedControl extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSegmentedControl({
    required this.themeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          final (mode, icon, label) = option;
          final isSelected = themeMode == mode;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? AppTheme.primaryTeal
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryTeal : Colors.grey,
      ),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryTeal)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
