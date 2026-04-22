import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:billify_application/core/constants/app_constants.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/core/services/local_storage_service.dart';
import 'package:billify_application/data/datasources/remote_invoice_datasource.dart';

class InvoiceRepository {
  final LocalStorageService _storage;
  final RemoteInvoiceDatasource _remoteDatasource;
  final String? _userId;
  final String _businessId;

  InvoiceRepository(this._storage, this._remoteDatasource, this._userId, this._businessId);

  String get _invoiceDataKey => AppConstants.businessKey(_userId ?? 'guest', _businessId, AppConstants.keyInvoiceData);

  Future<void> fetchAndSyncInvoices() async {
    if (int.tryParse(_businessId) == null) {
      debugPrint("INFO: Skipping invoice sync for non-numeric business ID: $_businessId");
      return;
    }
    try {
      final remoteInvoices = await _remoteDatasource.getInvoices(_businessId);
      final List<String> data = remoteInvoices.map((e) => jsonEncode(e.toJson())).toList();
      await _storage.setStringList(_invoiceDataKey, data);
    } catch (e) {
      print("Error syncing invoices: $e");
    }
  }

  Future<InvoiceModel> saveInvoice(InvoiceModel invoice) async {
    try {
      // 1. Post to Server
      final savedInvoice = await _remoteDatasource.createInvoice(invoice, _businessId, _userId);
      
      if (savedInvoice != null) {
        // 2. Prepend to Local Cache using the Server-Generated Invoice Structure (which has proper Invoice Number ID)
        final List<InvoiceModel> invoices = await getInvoices();
        invoices.insert(0, savedInvoice);
        final List<String> data = invoices.map((e) => jsonEncode(e.toJson())).toList();
        await _storage.setStringList(_invoiceDataKey, data);
        return savedInvoice;
      } else {
        throw Exception("Server rejected creating invoice");
      }
    } catch (e) {
      throw Exception("Network error saving invoice: $e");
    }
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final List<String>? data = _storage.getStringList(_invoiceDataKey);
    if (data == null) return [];
    try {
      return data.map((e) => InvoiceModel.fromJson(jsonDecode(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteInvoice(String id) async {
    // Current backend doesn't support deleting invoices (usually disallowed for audit reasons anyway)
    // We'll leave local deletion for logic purposes if necessary.
    final List<InvoiceModel> invoices = await getInvoices();
    invoices.removeWhere((e) => e.id == id);
    final List<String> data = invoices.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(_invoiceDataKey, data);
  }

  Future<InvoiceModel?> getInvoiceById(String id) async {
    return await _remoteDatasource.getInvoiceById(id);
  }
}
