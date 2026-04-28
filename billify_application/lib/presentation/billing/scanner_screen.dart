import 'dart:convert';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/image_utils.dart';
import 'package:billify_application/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify_application/presentation/product/product_management_page.dart';
import 'package:billify_application/providers/billing_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/data/models/cart_item_model.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:billify_application/providers/customer_provider.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/invoice_provider.dart';
import 'package:billify_application/presentation/billing/widgets/weight_input_sheet.dart';
import 'package:billify_application/presentation/widgets/error_handler.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasPermission = false;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    // Debounce: Prevent duplicate scans within 1.5 seconds
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }
    _lastScanTime = now;

    setState(() => _isProcessing = true);

    final billingNotifier = ref.read(billingProvider.notifier);
    final product = ref.read(productProvider.notifier).findByBarcode(barcode);

    if (product != null) {
      if (product.stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product ${product.name} is Out of Stock'),
            backgroundColor: Colors.red,
          ),
        );
        _resumeScanner();
        return;
      }

      // If product has variants but we scanned the main barcode, show variant picker
      if (product.hasVariants && product.selectedVariantId == null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _ProductPickerSheet(
            products: [product],
            onSelected: (selectedVariant) {
              if (ref
                  .read(billingProvider.notifier)
                  .addToCart(selectedVariant)) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Limited stock available')),
                );
              }
            },
          ),
        ).then((_) => _resumeScanner());
        return;
      }

      if (product.is_weighted) {
        _showWeightInput(product);
        return;
      }

      if (ref.read(billingProvider.notifier).addToCart(product)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limited stock available')),
        );
      }
      _resumeScanner();
    } else {
      if (ref
          .read(authProvider)
          .hasPermission(PermissionModule.products, PermissionAction.add)) {
        Navigator.push<ProductModel>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductManagementPage(initialBarcode: barcode),
          ),
        ).then((newProduct) {
          if (newProduct != null) {
            billingNotifier.addToCart(newProduct);
          }
          _resumeScanner();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Product not available & you are not granted to add new products',
            ),
          ),
        );
        _resumeScanner();
      }
    }
  }

  void _resumeScanner() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _showCustomerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerSelectorSheet(
        onSelected: (customerId, customerType) {
          ref
              .read(billingProvider.notifier)
              .setCustomer(customerId, customerType);
          Navigator.pop(context);
          _showInvoice(ref, context);
        },
      ),
    );
  }

  void _showInvoice(WidgetRef ref, BuildContext context) {
    final billingState = ref.read(billingProvider);
    final businessState = ref.read(businessProvider);
    final currentBusiness = businessState.currentBusiness;

    if (currentBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please setup business details first')),
      );
      return;
    }

    final taxPercent = currentBusiness.tax_percentage;
    final gstPercent = currentBusiness.gst_percentage;
    final invoiceNo =
        '${currentBusiness.invoice_prefix}${currentBusiness.starting_invoice_number}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ThermalInvoiceDialog(
        items: billingState.items,
        business: currentBusiness,
        subtotal: billingState.subtotal,
        taxAmount: billingState.calculateTax(taxPercent),
        gstAmount: billingState.calculateTax(gstPercent),
        total: billingState.getTotal(taxPercent, gstPercent),
        invoiceId: invoiceNo,
        invoiceDate: DateTime.now(),
        initialPaidAmount: billingState.getTotal(taxPercent, gstPercent),
        initialPaymentMode: 'CASH',
        customerId: billingState.selectedCustomerId,
        customerType: billingState.customerType,
      ),
    );
  }

  void _showProductPicker() {
    final allProducts = ref.read(productProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductPickerSheet(
        products: allProducts,
        onSelected: (product) {
          final billingNotifier = ref.read(billingProvider.notifier);
          if (product.is_weighted) {
            Navigator.pop(context);
            _showWeightInput(product);
          } else {
            billingNotifier.addToCart(product);
          }
        },
      ),
    );
  }

  void _showWeightInput(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeightInputSheet(
        product: product,
        onAdd: (quantity) {
          if (ref
              .read(billingProvider.notifier)
              .addToCart(product, quantity: quantity)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} added: $quantity KG')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Limited stock available')),
            );
          }
        },
      ),
    ).then((_) => _resumeScanner());
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final businessState = ref.watch(businessProvider);
    final business = businessState.currentBusiness;
    final taxPercent = business?.tax_percentage ?? 0.0;
    final gstPercent = business?.gst_percentage ?? 0.0;

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Product')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              const Text('Camera permission is required to scan barcodes'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Extension'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showProductPicker,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Static Scanner At Top
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleScan,
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Scanner Error: ${error.errorCode}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please check permissions',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _controller.start();
                                setState(() {});
                              },
                              child: const Text('RETRY'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                CustomPaint(
                  painter: _ScannerOverlayPainter(),
                  child: Container(),
                ),
                if (_isProcessing)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  ),
              ],
            ),
          ),

          // Scrollable List Below
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.background.withOpacity(0.8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scanned Items (${billingState.items.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          'Total: ₹${billingState.getTotal(taxPercent, gstPercent).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: billingState.items.isEmpty
                        ? Center(
                            child: Text(
                              'No items scanned yet',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: billingState.items.length,
                            itemBuilder: (context, index) {
                              final item = billingState.items[index];
                              return _PanelItemTile(item: item);
                            },
                          ),
                  ),

                  // Checkout Section
                  if (ref
                      .watch(authProvider)
                      .hasPermission(
                        PermissionModule.billing,
                        PermissionAction.add,
                      ))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: billingState.items.isEmpty
                            ? null
                            : () => _showCustomerSelector(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.print, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'CONFIRM & PRINT - ₹${billingState.getTotal(taxPercent, gstPercent).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSelectorSheet extends ConsumerWidget {
  final Function(int?, String) onSelected;

  const _CustomerSelectorSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final customers = customersAsync.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Select Customer',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryTeal,
              child: Icon(Icons.person_outline, color: Colors.white),
            ),
            title: const Text('Walk-in Customer'),
            subtitle: const Text('Default for quick sales'),
            onTap: () => onSelected(null, 'WALKIN'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search or filter customers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                // Implement local filter or logic if needed
              },
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No customers found'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to add customer or import
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Customer'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(customer.name[0])),
                        title: Text(customer.name),
                        subtitle: Text(customer.phoneNumber),
                        trailing: Text(
                          'Bal: ₹${customer.remainingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: customer.remainingBalance >= 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => onSelected(customer.id, 'REGULAR'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.fill;

    // Dimensions of the scan window relative to 250 height
    const double scanWidth = 200;
    const double scanHeight = 150;
    final double left = (size.width - scanWidth) / 2;
    final double top = (size.height - scanHeight) / 2;

    final Rect scanRect = Rect.fromLTWH(left, top, scanWidth, scanHeight);

    // Draw the dark background with the hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
        ),
      ),
      paint,
    );

    // Draw the frame corners
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const double cornerSize = 25;
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerSize)
        ..lineTo(left, top)
        ..lineTo(left + cornerSize, top),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + scanWidth - cornerSize, top)
        ..lineTo(left + scanWidth, top)
        ..lineTo(left + scanWidth, top + cornerSize),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanHeight - cornerSize)
        ..lineTo(left, top + scanHeight)
        ..lineTo(left + cornerSize, top + scanHeight),
      cornerPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + scanWidth - cornerSize, top + scanHeight)
        ..lineTo(left + scanWidth, top + scanHeight)
        ..lineTo(left + scanWidth, top + scanHeight - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onSelected;

  const _ProductPickerSheet({required this.products, required this.onSelected});

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  late List<ProductModel> _filteredProducts;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  void _filterProducts(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = widget.products.where((p) {
        final matchesProduct =
            p.name.toLowerCase().contains(lowerQuery) ||
            p.barcode.toLowerCase().contains(lowerQuery);
        if (matchesProduct) return true;

        if (p.hasVariants) {
          return p.variants.any(
            (v) =>
                v.name.toLowerCase().contains(lowerQuery) ||
                v.sku.toLowerCase().contains(lowerQuery),
          );
        }
        return false;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Select Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.background,
              ),
              onChanged: _filterProducts,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index];

                      if (!p.hasVariants || p.variants.isEmpty) {
                        return _ProductListTile(
                          product: p,
                          billingState: billingState,
                          onSelected: widget.onSelected,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ...p.variants.map((v) {
                            final variantProduct = p.copyWith(
                              name: v.name.isNotEmpty
                                  ? '${p.name} (${v.name})'
                                  : p.name,
                              basePrice: v.price,
                              stock: v.stock,
                              barcode: v.sku,
                              selectedVariantId: v.id,
                              uom: v.uom,
                            );
                            return _ProductListTile(
                              product: variantProduct,
                              billingState: billingState,
                              onSelected: widget.onSelected,
                              isVariant: true,
                            );
                          }).toList(),
                          const Divider(height: 24),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductListTile extends ConsumerWidget {
  final ProductModel product;
  final BillingState billingState;
  final Function(ProductModel) onSelected;
  final bool isVariant;

  const _ProductListTile({
    required this.product,
    required this.billingState,
    required this.onSelected,
    this.isVariant = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemIndex = billingState.items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          i.product.selectedVariantId == product.selectedVariantId,
    );
    final isInCart = cartItemIndex >= 0;
    final quantity = isInCart ? billingState.items[cartItemIndex].quantity : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isInCart
            ? const BorderSide(color: AppTheme.primaryTeal, width: 1.5)
            : BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          isVariant
              ? product.name.split(' (').last.replaceAll(')', '')
              : product.name,
          style: TextStyle(
            fontWeight: isVariant ? FontWeight.w500 : FontWeight.bold,
            fontSize: isVariant ? 14 : 16,
          ),
        ),
        subtitle: Text(
          'Stock: ${product.is_weighted ? product.stock.toStringAsFixed(3) : product.stock.toInt()} | Barcode: ${product.barcode}',
          style: TextStyle(
            color: product.stock <= 0
                ? Colors.red
                : Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
            fontWeight: product.stock <= 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${product.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                if (isInCart)
                  const Text(
                    'In Cart',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            if (!isInCart)
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: product.stock <= 0
                      ? Colors.grey
                      : AppTheme.primaryTeal,
                ),
                onPressed: product.stock <= 0
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product out of stock')),
                        );
                      }
                    : () => onSelected(product),
              )
            else if (ref
                .watch(authProvider)
                .hasPermission(
                  PermissionModule.billing,
                  PermissionAction.update,
                ))
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => ref
                          .read(billingProvider.notifier)
                          .updateQuantity(
                            product.id,
                            quantity - 1,
                            variantId: product.selectedVariantId,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        product.is_weighted
                            ? quantity.toStringAsFixed(3)
                            : quantity.toInt().toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        if (!ref
                            .read(billingProvider.notifier)
                            .updateQuantity(
                              product.id,
                              quantity + 1,
                              variantId: product.selectedVariantId,
                            )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Limited stock available'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              )
            else if (isInCart)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Qty: $quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          if (!isInCart) {
            if (product.stock > 0) {
              onSelected(product);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product out of stock')),
              );
            }
          }
        },
      ),
    );
  }
}

class _PanelItemTile extends ConsumerWidget {
  final CartItemModel item; // Corrected type

  const _PanelItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(
        'cart_item_${item.product.id}_${item.product.selectedVariantId}',
      ),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref
            .read(billingProvider.notifier)
            .removeFromCart(
              item.product.id,
              variantId: item.product.selectedVariantId,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from cart'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref
                    .read(billingProvider.notifier)
                    .addToCart(item.product, quantity: item.quantity);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  item.product.photo != null && item.product.photo!.isNotEmpty
                  ? Image.memory(
                      ImageUtils.decodeBase64(item.product.photo!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryTeal,
                    ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  Text(
                    '₹${item.product.is_weighted ? item.product.price_per_unit.toStringAsFixed(2) : item.price.toStringAsFixed(2)}${item.product.uom.isNotEmpty ? ' / ${item.product.uom}' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (ref
                .watch(authProvider)
                .hasPermission(
                  PermissionModule.billing,
                  PermissionAction.update,
                ))
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        size: 18,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => ref
                          .read(billingProvider.notifier)
                          .updateQuantity(
                            item.product.id,
                            item.quantity - 1,
                            variantId: item.product.selectedVariantId,
                          ),
                    ),
                    Text(
                      item.product.is_weighted
                          ? item.quantity.toStringAsFixed(3)
                          : item.quantity.toInt().toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        size: 18,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        if (!ref
                            .read(billingProvider.notifier)
                            .updateQuantity(
                              item.product.id,
                              item.quantity + 1,
                              variantId: item.product.selectedVariantId,
                            )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Limited stock available'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'x${item.product.is_weighted ? item.quantity.toStringAsFixed(3) : item.quantity.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '₹${item.subtotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
