import 'dart:convert';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceRepository {
  final SharedPreferences _prefs;

  InvoiceRepository(this._prefs);

  Future<void> saveInvoice(InvoiceModel invoice) async {
    final List<InvoiceModel> invoices = await getInvoices();
    invoices.insert(0, invoice); // Most recent first
    final List<String> data = invoices.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(AppConstants.keyInvoiceData, data);
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final List<String>? data = _prefs.getStringList(AppConstants.keyInvoiceData);
    if (data == null) return [];
    return data.map((e) => InvoiceModel.fromJson(jsonDecode(e))).toList();
  }

  Future<void> deleteInvoice(String id) async {
    final List<InvoiceModel> invoices = await getInvoices();
    invoices.removeWhere((e) => e.id == id);
    final List<String> data = invoices.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(AppConstants.keyInvoiceData, data);
  }
}
