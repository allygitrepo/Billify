import 'dart:convert';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/models/registration_model.dart';
import 'package:billify_application/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationNotifier extends StateNotifier<RegistrationModel?> {
  final LocalStorageService _storage;
  static const String _storageKey = 'temp_registration_data';

  RegistrationNotifier(this._storage) : super(null) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final data = _storage.getString(_storageKey);
    if (data != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(data);
        // We need a fromJson in RegistrationModel, adding it conceptually here
        // or just mapping manually.
        state = RegistrationModel(
          name: json['name'] ?? '',
          email: json['email'] ?? '',
          password: json['password'] ?? '',
          phone: json['userMobile'],
          businessName: json['business_name'] ?? '',
          businessPhone: json['phone'],
          gstin: json['gstin'],
          address: json['address'],
          taxPercentage: double.tryParse(json['taxPercentage']?.toString() ?? ''),
          gstPercentage: double.tryParse(json['gstPercentage']?.toString() ?? ''),
          currency: json['currency'],
          invoicePrefix: json['invoicePrefix'],
          startingNumber: json['startingNumber'],
          invoiceFormat: json['invoiceFormat'],
          footerNote: json['footerNote'],
        );
      } catch (_) {
        _storage.remove(_storageKey);
      }
    }
  }

  Future<void> updateUserStep({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final newState = (state ?? RegistrationModel(
      name: name,
      email: email,
      password: password,
      businessName: '',
    )).copyWith(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    state = newState;
    await _storage.setString(_storageKey, jsonEncode(newState.toJson()));
  }

  Future<void> updateBusinessStep({
    required String businessName,
    String? businessPhone,
    String? gstin,
    String? address,
    String? logo,
    double? taxPercentage,
    double? gstPercentage,
    String? invoicePrefix,
    int? startingNumber,
  }) async {
    if (state == null) return;
    
    final newState = state!.copyWith(
      businessName: businessName,
      businessPhone: businessPhone,
      gstin: gstin,
      address: address,
      businessPhoto: logo,
      taxPercentage: taxPercentage,
      gstPercentage: gstPercentage,
      invoicePrefix: invoicePrefix,
      startingNumber: startingNumber,
    );
    state = newState;
    await _storage.setString(_storageKey, jsonEncode(newState.toJson()));
  }

  Future<void> clear() async {
    state = null;
    await _storage.remove(_storageKey);
  }
}

final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationModel?>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return RegistrationNotifier(storage);
});
