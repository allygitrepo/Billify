import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/core/services/local_storage_service.dart';

class InvoiceRepository {
  final LocalStorageService _storage;
  final String _userId;

  InvoiceRepository(this._storage, this._userId);

  String get _invoiceDataKey => AppConstants.userKey(_userId, AppConstants.keyInvoiceData);

  Future<void> saveInvoice(InvoiceModel invoice) async {
    final List<InvoiceModel> invoices = await getInvoices();
    invoices.insert(0, invoice); // Most recent first
    final List<String> data = invoices.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(_invoiceDataKey, data);
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final List<String>? data = _storage.getStringList(_invoiceDataKey);
    if (data == null) return [];
    return data.map((e) => InvoiceModel.fromJson(jsonDecode(e))).toList();
  }

  Future<void> deleteInvoice(String id) async {
    final List<InvoiceModel> invoices = await getInvoices();
    invoices.removeWhere((e) => e.id == id);
    final List<String> data = invoices.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(_invoiceDataKey, data);
  }
}
