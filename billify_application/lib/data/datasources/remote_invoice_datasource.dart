import 'package:billify_application/core/constants/api_endpoints.dart';
import 'package:billify_application/core/services/api_service.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final remoteInvoiceDatasourceProvider = Provider<RemoteInvoiceDatasource>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RemoteInvoiceDatasource(apiService);
});

class RemoteInvoiceDatasource {
  final ApiService _apiService;

  RemoteInvoiceDatasource(this._apiService);

  Future<List<InvoiceModel>> getInvoices(String businessId) async {
    final response = await _apiService.get(ApiEndpoints.getInvoices(businessId));
    if (response.statusCode == 200) {
      final data = response.data['invoices'] as List;
      return data.map((json) => InvoiceModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<InvoiceModel?> createInvoice(InvoiceModel invoice, String businessId, String? userId) async {
    final double totalTaxes = (invoice.tax_amount) + (invoice.gst_amount);
    final String mode = (invoice.paid_amount >= invoice.final_amount) ? 'Cash' : (invoice.paid_amount <= 0 ? 'Khata' : 'Split');
    final String status = (invoice.paid_amount >= invoice.final_amount) ? 'Paid' : 'Pending';

    final Map<String, dynamic> body = {
        'business_id': businessId,
        'customer_id': invoice.customer_id,
        'customer_type': invoice.customer_type,
        'customer_name': invoice.customer_id != null ? 'Regular Customer' : 'Walk-in Customer', 
        'customer_phone': '',
        'total_amount': invoice.total_amount,
        'discount': 0, 
        'tax_amount': totalTaxes, 
        'final_amount': invoice.final_amount,
        'paid_amount': invoice.paid_amount,
        'payment_mode': mode,
        'status': status,
        'user_id': userId,
        'items': invoice.items.map((item) {
          return {
            'productId': item.product.id,
            'productName': item.customName?.isNotEmpty == true ? item.customName! : item.product.name,
            'variantName': item.product.selectedVariantId != null 
                ? item.product.variants.where((v) => v.id == item.product.selectedVariantId).firstOrNull?.name 
                : null,
            'quantity': item.quantity,
            'price': item.price,
            'subtotal': item.subtotal
          };
        }).toList()
    };

    print('DEBUG: Sending CREATE_INVOICE body: $body');

    final response = await _apiService.post(
      ApiEndpoints.createInvoice,
      data: body,
    );
    if (response.statusCode == 201) {
      final serverData = response.data['invoice'];
      return invoice.copyWith(
        id: serverData['invoice_number']?.toString() ?? serverData['id']?.toString(),
        date: serverData['createdAt'] != null ? DateTime.parse(serverData['createdAt']) : invoice.date,
      );
    }
    return null;
  }

  Future<InvoiceModel?> getInvoiceById(String id) async {
    try {
      final response = await _apiService.get("${ApiEndpoints.invoicesBase}/$id");
      if (response.statusCode == 200) {
        return InvoiceModel.fromJson(response.data['invoice']);
      }
      return null;
    } catch (e) {
      print("Error fetching invoice by ID ($id): $e");
      return null;
    }
  }
}
