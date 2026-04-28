import 'dart:convert';
import 'package:billify/data/models/feature_settings_model.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureSettingsNotifier extends Notifier<FeatureSettingsModel> {
  String get _storageKey {
    final email = ref.watch(authProvider).user?.email ?? 'guest';
    return 'feature_settings_$email';
  }

  @override
  FeatureSettingsModel build() {
    final storage = ref.watch(localStorageServiceProvider);
    final jsonString = storage.getString(_storageKey);
    if (jsonString != null) {
      try {
        return FeatureSettingsModel.fromJson(jsonDecode(jsonString));
      } catch (e) {
        return FeatureSettingsModel();
      }
    }
    return FeatureSettingsModel();
  }

  Future<void> updateCategoryEnabled(bool value) async {
    state = state.copyWith(isCategoryEnabled: value);
    await _save();
  }

  Future<void> updateVariantsEnabled(bool value) async {
    state = state.copyWith(isVariantsEnabled: value);
    await _save();
  }

  Future<void> _save() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(_storageKey, jsonEncode(state.toJson()));
  }
}

final featureSettingsProvider =
    NotifierProvider<FeatureSettingsNotifier, FeatureSettingsModel>(() {
      return FeatureSettingsNotifier();
    });
