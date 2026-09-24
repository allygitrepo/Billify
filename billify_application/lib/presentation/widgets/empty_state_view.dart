import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Production Empty State view with subtle glow backdrop, crisp typography,
/// and contextual primary/secondary action triggers.
class EmptyStateView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final Widget? customAction;

  const EmptyStateView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add_rounded,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryTeal.withValues(alpha: isDark ? 0.25 : 0.12),
                    AppTheme.secondaryTeal.withValues(alpha: isDark ? 0.15 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 42,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (customAction != null) ...[
              const SizedBox(height: 24),
              customAction!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  elevation: 2,
                ),
                onPressed: onAction,
                icon: Icon(actionIcon, size: 18),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
