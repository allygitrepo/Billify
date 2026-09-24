import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production design-system button supporting Primary Gradient, Danger/Destructive,
/// Secondary Outlined, Icon actions, and responsive tactile haptic feedback.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDanger;
  final IconData? icon;
  final Color? color;
  final bool isGradient;
  final double height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDanger = false,
    this.icon,
    this.color,
    this.isGradient = true,
    this.height = 50.0,
    this.width,
  });

  void _handleTap() {
    if (onPressed != null && !isLoading) {
      HapticFeedback.lightImpact();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDanger
        ? Colors.redAccent
        : (color ?? AppTheme.primaryTeal);

    if (isSecondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: (onPressed == null || isLoading) ? null : _handleTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: onPressed == null
                  ? Colors.grey.shade400
                  : effectiveColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: effectiveColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: effectiveColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: effectiveColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    final isInteractive = onPressed != null && !isLoading;
    final gradient = (!isInteractive || !isGradient)
        ? null
        : (isDanger
            ? const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.tealGradient);

    final backgroundColor = !isInteractive
        ? Colors.grey.shade400
        : (isGradient ? null : effectiveColor);

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: backgroundColor,
        boxShadow: isInteractive
            ? [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isInteractive ? _handleTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
