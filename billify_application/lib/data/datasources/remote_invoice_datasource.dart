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
    final response = await _apiService.post(
      ApiEndpoints.createInvoice,
      data: {
        'business_id': businessId,
        'customer_name': 'Walk-in Customer', // Defaulting for MVP
        'customer_phone': '',
        'total_amount': invoice.total_amount,
        'discount': 0, // Currently not used in model directly as top level
        'tax_amount': invoice.tax_amount + invoice.gst_amount, // Combine taxes
        'final_amount': invoice.final_amount,
        'payment_mode': 'Cash',
        'status': 'Paid',
        'user_id': userId,
        'items': invoice.items.map((item) {
          return {
            'productId': item.product.id,
            'productName': item.customName?.isNotEmpty == true ? item.customName! : item.product.name,
            'variantName': item.product.selectedVariantId != null ? item.product.variants.firstWhere((v) => v.id == item.product.selectedVariantId, orElse: () => item.product.variants.first).name : null,
            'quantity': item.quantity,
            'price': item.price,
            'subtotal': item.subtotal
          };
        }).toList()
      },
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
}
