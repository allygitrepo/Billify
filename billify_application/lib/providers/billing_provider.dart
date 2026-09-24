import 'package:billify/core/utils/app_logger.dart';
import 'package:billify/data/models/business_model.dart';
import 'package:billify/data/models/cart_item_model.dart';
import 'package:billify/data/models/invoice_model.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/invoice_provider.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:billify/providers/customer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingState {
  final List<CartItemModel> items;
  final bool isProcessing;
  final int? selectedCustomerId;
  final String customerType; // 'WALKIN', 'REGULAR'
  final double paidAmount;

  BillingState({
    this.items = const [],
    this.isProcessing = false,
    this.selectedCustomerId,
    this.customerType = 'WALKIN',
    this.paidAmount = 0.0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double calculateTax(double percent) {
    return subtotal * (percent / 100);
  }

  double getTotal(double taxPercent, double gstPercent) {
    return subtotal + calculateTax(taxPercent) + calculateTax(gstPercent);
  }

  BillingState copyWith({
    List<CartItemModel>? items,
    bool? isProcessing,
    int? selectedCustomerId,
    String? customerType,
    double? paidAmount,
  }) {
    return BillingState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      customerType: customerType ?? this.customerType,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }
}

class BillingNotifier extends Notifier<BillingState> {
  @override
  BillingState build() {
    return BillingState();
  }

  void setCustomer(int? id, String type) {
    state = state.copyWith(selectedCustomerId: id, customerType: type);
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  bool addToCart(ProductModel product, {double? quantity}) {
    if (product.stock <= 0) {
      AppLogger.warning(
        'Cannot add to cart - Product ${product.name} is out of stock!',
        tag: 'BillingNotifier',
      );
      return false;
    }

    final index = state.items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          i.product.selectedVariantId == product.selectedVariantId,
    );

    final double qtyToAdd = quantity ?? (product.is_weighted ? 0.0 : 1.0);
    if (qtyToAdd == 0.0 && product.is_weighted && quantity == null) {
      // Return true but don't add yet, caller should show weight input
      return true;
    }

    if (index >= 0) {
      final existingItem = state.items[index];
      // Check if we have enough stock
      if (existingItem.quantity + qtyToAdd > product.stock) {
        AppLogger.warning(
          'Cannot add more - Limited stock for ${product.name}',
          tag: 'BillingNotifier',
        );
        return false;
      }
      final updatedItems = List<CartItemModel>.from(state.items);
      updatedItems[index] = existingItem.copyWith(
        quantity: existingItem.quantity + qtyToAdd,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItemModel(product: product, quantity: qtyToAdd),
        ],
      );
    }
    return true;
  }

  Future<InvoiceModel?> confirmInvoice(BusinessModel business) async {
    if (state.items.isEmpty || state.isProcessing) return null;

    state = state.copyWith(isProcessing: true);

    try {
      // Generate placeholder ID (Server will assign correct sequential Number)
      final invoiceId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      final currentUser = ref.read(authProvider).user;
      final staffName = currentUser?.name ?? 'Owner';

      final invoice = InvoiceModel(
        id: invoiceId,
        date: DateTime.now(),
        business: business,
        items: state.items,
        total_amount: state.subtotal,
        tax_amount: state.calculateTax(business.tax_percentage),
        gst_amount: state.calculateTax(business.gst_percentage),
        final_amount: state.getTotal(
          business.tax_percentage,
          business.gst_percentage,
        ),
        staff_name: staffName,
        customer_id: state.selectedCustomerId,
        customer_type: state.customerType,
        paid_amount: state.paidAmount,
      );

      // Save to server & history
      final serverInvoice = await ref
          .read(invoiceProvider.notifier)
          .addInvoice(invoice);

      // Update customerProvider state synchronously before returning
      ref.invalidate(customerProvider);
      if (serverInvoice.customer_id != null) {
        // Await the actual refresh to ensure next screen has fresh data
        await ref.refresh(
          customerLedgerProvider(serverInvoice.customer_id!).future,
        );
      }

      // Sync products mathematically from the server
      ref
          .read(productProvider.notifier)
          .fetchAndSyncProducts(); // Async background update

      // Clear cart
      clearCart();

      return serverInvoice;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  void addByBarcode(String barcode, {Function(String)? onNotFound}) {
    final product = ref.read(productProvider.notifier).findByBarcode(barcode);
    if (product != null) {
      addToCart(product);
    } else {
      onNotFound?.call(barcode);
    }
  }

  bool updateQuantity(
    String productId,
    double newQuantity, {
    String? variantId,
  }) {
    if (newQuantity <= 0) {
      removeFromCart(productId, variantId: variantId);
      return true;
    }

    final itemIndex = state.items.indexWhere(
      (i) =>
          i.product.id == productId && i.product.selectedVariantId == variantId,
    );

    if (itemIndex == -1) return false;
    final item = state.items[itemIndex];

    // STOCK VALIDATION
    if (newQuantity > item.product.stock) {
      AppLogger.warning(
        'Cannot update quantity - Exceeds stock (${item.product.stock})',
        tag: 'BillingNotifier',
      );
      return false;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId &&
          item.product.selectedVariantId == variantId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
    return true;
  }

  void updateItem(
    String productId, {
    String? variantId,
    String? customName,
    double? customPrice,
  }) {
    final updatedItems = state.items.map((item) {
      if (item.product.id == productId &&
          item.product.selectedVariantId == variantId) {
        return item.copyWith(customName: customName, customPrice: customPrice);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeFromCart(String productId, {String? variantId}) {
    state = state.copyWith(
      items: state.items
          .where(
            (i) =>
                i.product.id != productId ||
                i.product.selectedVariantId != variantId,
          )
          .toList(),
    );
  }

  void clearCart() {
    state = BillingState();
  }
}

final billingProvider = NotifierProvider<BillingNotifier, BillingState>(
  BillingNotifier.new,
);
