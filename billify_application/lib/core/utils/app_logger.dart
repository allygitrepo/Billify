import 'package:flutter/foundation.dart';

/// Centralized structured logger for the Billify application.
/// Ensures all debug output is automatically silenced in production release builds.
class AppLogger {
  AppLogger._();

  /// Logs general informational messages
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ [INFO] $tagStr$message');
    }
  }

  /// Logs detailed debug diagnostics
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('🔍 [DEBUG] $tagStr$message');
    }
  }

  /// Logs non-fatal warnings
  static void warning(String message, {String? tag, dynamic error}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      final errStr = error != null ? ' | Error: $error' : '';
      debugPrint('⚠️ [WARN] $tagStr$message$errStr');
    }
  }

  /// Logs errors, unexpected exceptions, and stack traces
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      final errStr = error != null ? '\nError: $error' : '';
      final stackStr = stackTrace != null ? '\nStackTrace:\n$stackTrace' : '';
      debugPrint('🛑 [ERROR] $tagStr$message$errStr$stackStr');
    }
    // In production, integrate with Crashlytics or remote Sentry logger here
  }
}
