import 'package:flutter/material.dart';

enum BadgeVariant {
  success,
  warning,
  danger,
  info,
  neutral,
}

/// Production-grade Status Badge supporting soft tint halos, high-contrast text,
/// dynamic icons, and responsive pill formatting.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.info,
    this.icon,
    this.isSmall = false,
  });

  // Specialized convenience constructors
  factory StatusBadge.inStock({String label = 'In Stock'}) =>
      StatusBadge(label: label, variant: BadgeVariant.success, icon: Icons.check_circle_outline);

  factory StatusBadge.lowStock({String label = 'Low Stock'}) =>
      StatusBadge(label: label, variant: BadgeVariant.warning, icon: Icons.warning_amber_rounded);

  factory StatusBadge.outOfStock({String label = 'Out of Stock'}) =>
      StatusBadge(label: label, variant: BadgeVariant.danger, icon: Icons.cancel_outlined);

  factory StatusBadge.active({String label = 'Active'}) =>
      StatusBadge(label: label, variant: BadgeVariant.success);

  factory StatusBadge.inactive({String label = 'Inactive'}) =>
      StatusBadge(label: label, variant: BadgeVariant.neutral);

  factory StatusBadge.paid({String label = 'Paid'}) =>
      StatusBadge(label: label, variant: BadgeVariant.success, icon: Icons.done_all_rounded);

  factory StatusBadge.partial({String label = 'Partial'}) =>
      StatusBadge(label: label, variant: BadgeVariant.warning, icon: Icons.pie_chart_outline);

  factory StatusBadge.unpaid({String label = 'Unpaid'}) =>
      StatusBadge(label: label, variant: BadgeVariant.danger, icon: Icons.schedule_rounded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (Color primaryColor, Color bgColor) = switch (variant) {
      BadgeVariant.success => (
        const Color(0xFF2E7D32),
        const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.25 : 0.1),
      ),
      BadgeVariant.warning => (
        const Color(0xFFED6C02),
        const Color(0xFFED6C02).withValues(alpha: isDark ? 0.25 : 0.12),
      ),
      BadgeVariant.danger => (
        const Color(0xFFD32F2F),
        const Color(0xFFD32F2F).withValues(alpha: isDark ? 0.25 : 0.1),
      ),
      BadgeVariant.info => (
        const Color(0xFF0288D1),
        const Color(0xFF0288D1).withValues(alpha: isDark ? 0.25 : 0.1),
      ),
      BadgeVariant.neutral => (
        Colors.grey.shade600,
        Colors.grey.shade600.withValues(alpha: isDark ? 0.25 : 0.1),
      ),
    };

    final horizontalPadding = isSmall ? 8.0 : 10.0;
    final verticalPadding = isSmall ? 3.0 : 5.0;
    final fontSize = isSmall ? 11.0 : 12.0;
    final iconSize = isSmall ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: primaryColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
