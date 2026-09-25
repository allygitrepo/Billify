import 'dart:async';
import 'package:billify/core/errors/app_failure.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized UX feedback manager providing tactile haptics, top-overlay floating Toasts
/// that appear above all dialogs, bottom sheets, and forms, confirmation modals, and automatic keyboard dismissal.
class AppFeedback {
  AppFeedback._();

  static _ActiveToast? _currentToast;

  /// Dismisses active virtual keyboard across the app
  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Displays a floating success feedback pill with haptics at the top of the screen (above all modals)
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    HapticFeedback.lightImpact();

    _showOverlayToast(
      context: context,
      message: message,
      type: _ToastType.success,
    );
  }

  /// Displays a floating error feedback pill with haptics and retry option at the top of the screen (above all modals)
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

    _showOverlayToast(
      context: context,
      message: message,
      type: _ToastType.error,
      onRetry: onRetry,
    );
  }

  /// Displays an informative floating pill at the top of the screen (above all modals)
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    HapticFeedback.selectionClick();

    _showOverlayToast(
      context: context,
      message: message,
      type: _ToastType.info,
    );
  }

  /// Displays a warning floating pill at the top of the screen (above all modals)
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();

    _showOverlayToast(
      context: context,
      message: message,
      type: _ToastType.warning,
    );
  }

  static void _showOverlayToast({
    required BuildContext context,
    required String message,
    required _ToastType type,
    VoidCallback? onRetry,
  }) {
    // Dismiss any previous toast immediately
    _currentToast?.dismiss();
    _currentToast = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);

    if (overlay == null) {
      // Fallback for tests / headless environments
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: type.backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    late OverlayEntry entry;
    final animationKey = GlobalKey<_TopToastWidgetState>();

    entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        key: animationKey,
        message: message,
        type: type,
        onRetry: onRetry,
        onDismiss: () {
          entry.remove();
          if (_currentToast?.entry == entry) {
            _currentToast = null;
          }
        },
      ),
    );

    _currentToast = _ActiveToast(entry: entry, stateKey: animationKey);
    overlay.insert(entry);
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

enum _ToastType {
  success(
    backgroundColor: Color(0xFF1B5E20),
    icon: Icons.check_circle_rounded,
    iconColor: Colors.white,
  ),
  error(
    backgroundColor: Color(0xFFC62828),
    icon: Icons.error_outline_rounded,
    iconColor: Colors.white,
  ),
  info(
    backgroundColor: Color(0xFF1565C0),
    icon: Icons.info_outline_rounded,
    iconColor: Colors.white,
  ),
  warning(
    backgroundColor: Color(0xFFE65100),
    icon: Icons.warning_amber_rounded,
    iconColor: Colors.white,
  );

  const _ToastType({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
}

class _ActiveToast {
  final OverlayEntry entry;
  final GlobalKey<_TopToastWidgetState> stateKey;

  _ActiveToast({required this.entry, required this.stateKey});

  void dismiss() {
    try {
      stateKey.currentState?.dismissAnimated();
    } catch (_) {
      try {
        entry.remove();
      } catch (_) {}
    }
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final _ToastType type;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    super.key,
    required this.message,
    required this.type,
    this.onRetry,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      dismissAnimated();
    });
  }

  void dismissAnimated() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss();
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  dismissAnimated();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: widget.type.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.type.icon,
                        color: widget.type.iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (widget.onRetry != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          dismissAnimated();
                          widget.onRetry!();
                        },
                        child: const Text(
                          'RETRY',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: dismissAnimated,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

