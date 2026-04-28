import 'package:billify/core/constants/app_constants.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final storage = ref.read(localStorageServiceProvider);
    final themeStr = storage.getString(AppConstants.keyThemeMode);
    if (themeStr != null) {
      return ThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    return ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(AppConstants.keyThemeMode, mode.toString());
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
