import 'package:billify/core/errors/app_failure.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized UX feedback manager providing tactile haptics, floating SnackBars,
/// confirmation modals, and automatic keyboard dismissal.
class AppFeedback {
  AppFeedback._();

  /// Dismisses active virtual keyboard across the app
  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Displays a floating success feedback pill with haptics
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32), // Emerald Green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Displays a floating error feedback pill with haptics and retry option
  static void showError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;
    HapticFeedback.heavyImpact();

    final String message;
    if (error is AppFailure) {
      message = error.message;
    } else if (error is String) {
      message = error;
    } else {
      message = error?.toString() ?? 'An unexpected error occurred';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          action: onRetry != null
              ? SnackBarAction(
                  label: 'RETRY',
                  textColor: Colors.amberAccent,
                  onPressed: onRetry,
                )
              : null,
          backgroundColor: const Color(0xFFD32F2F), // Red 700
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Displays an informative floating pill
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1976D2), // Blue 700
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Shows a confirmation dialog with custom action titles
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (isDestructive)
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24)
            else
              const Icon(Icons.help_outline_rounded, color: AppTheme.primaryTeal, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.redAccent : AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(ctx).pop(true);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
