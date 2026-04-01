import 'package:billify_application/core/enums/stock_mode.dart';
import 'package:billify_application/data/models/business_model.dart';
import 'package:billify_application/data/models/cart_item_model.dart';
import 'package:billify_application/data/models/invoice_model.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/invoice_provider.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<CartItemModel> items;
  final bool isProcessing;

  BillingState({this.items = const [], this.isProcessing = false});

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  
  double calculateTax(double percent) {
    return subtotal * (percent / 100);
  }

  double getTotal(double taxPercent, double gstPercent) {
    return subtotal + calculateTax(taxPercent) + calculateTax(gstPercent);
  }

  BillingState copyWith({List<CartItemModel>? items, bool? isProcessing}) {
    return BillingState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class BillingNotifier extends Notifier<BillingState> {
  @override
  BillingState build() {
    return BillingState();
  }

  void addToCart(ProductModel product) {
    final index = state.items.indexWhere(
      (i) => i.product.id == product.id && i.product.selectedVariantId == product.selectedVariantId,
    );
    
    if (index >= 0) {
      final existingItem = state.items[index];
      final updatedItems = List<CartItemModel>.from(state.items);
      updatedItems[index] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItemModel(product: product)]);
    }
  }

  Future<void> confirmInvoice(BusinessModel business) async {
    if (state.items.isEmpty) return;

    // Generate sequential ID
    final invoiceId = '${business.invoicePrefix}${business.nextInvoiceNumber}';
    final currentUser = ref.read(authProvider).user;
    final staffName = currentUser?.fullName ?? 'Owner';

    final invoice = InvoiceModel(
      id: invoiceId,
      date: DateTime.now(),
      business: business,
      items: state.items,
      subtotal: state.subtotal,
      taxAmount: state.calculateTax(business.tax),
      gstAmount: state.calculateTax(business.gst),
      total: state.getTotal(business.tax, business.gst),
      staffName: staffName,
    );

    // Save to history
    await ref.read(invoiceProvider.notifier).addInvoice(invoice);
    
    // Increment business sequence
    await ref.read(businessProvider.notifier).updateBusiness(
      business.copyWith(nextInvoiceNumber: business.nextInvoiceNumber + 1),
    );
    
    // Deduct Stock
    final Map<String, int> stockDeltas = {};
    for (var item in state.items) {
      final key = item.product.selectedVariantId != null 
        ? '${item.product.id}:${item.product.selectedVariantId}' 
        : item.product.id;
      stockDeltas[key] = (stockDeltas[key] ?? 0) - item.quantity;
    }
    await ref.read(productProvider.notifier).updateStockBulk(
      stockDeltas,
      mode: StockMode.outMode,
      reason: 'Sale: Invoice ${invoice.id}',
      source: 'invoice',
    );

    // Clear cart
    clearCart();
  }

  void addByBarcode(String barcode, {Function(String)? onNotFound}) {
    final product = ref.read(productProvider.notifier).findByBarcode(barcode);
    if (product != null) {
      addToCart(product);
    } else {
      onNotFound?.call(barcode);
    }
  }

  void updateQuantity(String productId, int newQuantity, {String? variantId}) {
    if (newQuantity <= 0) {
      removeFromCart(productId, variantId: variantId);
      return;
    }
    
    final updatedItems = state.items.map((item) {
      if (item.product.id == productId && item.product.selectedVariantId == variantId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateItem(String productId, {String? variantId, String? customName, double? customPrice}) {
    final updatedItems = state.items.map((item) {
      if (item.product.id == productId && item.product.selectedVariantId == variantId) {
        return item.copyWith(customName: customName, customPrice: customPrice);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeFromCart(String productId, {String? variantId}) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId || i.product.selectedVariantId != variantId).toList(),
    );
  }

  void clearCart() {
    state = BillingState();
  }
}

final billingProvider = NotifierProvider<BillingNotifier, BillingState>(BillingNotifier.new);
