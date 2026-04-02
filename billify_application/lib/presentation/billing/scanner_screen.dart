import 'dart:convert';
import 'package:billify_application/core/theme/app_theme.dart';
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
    if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }
    _lastScanTime = now;

    setState(() => _isProcessing = true);

    final billingNotifier = ref.read(billingProvider.notifier);
    final product = ref.read(productProvider.notifier).findByBarcode(barcode);

    if (product != null) {
      // If product has variants but we scanned the main barcode, show variant picker
      if (product.hasVariants && product.selectedVariantId == null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _ProductPickerSheet(
            products: [product],
            onSelected: (selectedVariant) {
              billingNotifier.addToCart(selectedVariant);
              Navigator.pop(context);
            },
          ),
        ).then((_) => _resumeScanner());
        return;
      }

      billingNotifier.addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _resumeScanner();
    } else {
      Navigator.push<ProductModel>(
        context,
        MaterialPageRoute(
          builder: (context) => ProductManagementPage(initialBarcode: barcode),
        ),
      ).then((newProduct) {
        if (newProduct != null) {
          billingNotifier.addToCart(newProduct);
        }
        _resumeScanner();
      });
    }
  }

  void _resumeScanner() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
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
    final invoiceNo = '${currentBusiness.invoice_prefix}${currentBusiness.starting_invoice_number}';

    showDialog(
      context: context,
      builder: (context) => ThermalInvoiceDialog(
        items: billingState.items,
        business: currentBusiness,
        subtotal: billingState.subtotal,
        taxAmount: billingState.calculateTax(taxPercent),
        gstAmount: billingState.calculateTax(gstPercent),
        total: billingState.getTotal(taxPercent, gstPercent),
        invoiceId: invoiceNo,
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
          billingNotifier.addToCart(product);
        },
      ),
    );
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
                ),
                CustomPaint(
                  painter: _ScannerOverlayPainter(),
                  child: Container(),
                ),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
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
                            color: Theme.of(context).textTheme.titleLarge?.color,
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
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
                      onPressed: billingState.items.isEmpty ? null : () => _showInvoice(ref, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.print, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'CONFIRM & PRINT - ₹${billingState.getTotal(taxPercent, gstPercent).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12))),
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

  const _ProductPickerSheet({
    required this.products,
    required this.onSelected,
  });

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
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
        final matchesProduct = p.name.toLowerCase().contains(lowerQuery) || 
                             p.barcode.toLowerCase().contains(lowerQuery);
        if (matchesProduct) return true;
        
        if (p.hasVariants) {
          return p.variants.any((v) => 
            v.name.toLowerCase().contains(lowerQuery) || 
            v.sku.toLowerCase().contains(lowerQuery)
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
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                            ),
                          ),
                          ...p.variants.map((v) {
                            final variantProduct = p.copyWith(
                              name: v.name.isNotEmpty ? '${p.name} (${v.name})' : p.name,
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
      (i) => i.product.id == product.id && i.product.selectedVariantId == product.selectedVariantId
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
          : BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          isVariant ? product.name.split(' (').last.replaceAll(')', '') : product.name,
          style: TextStyle(
            fontWeight: isVariant ? FontWeight.w500 : FontWeight.bold,
            fontSize: isVariant ? 14 : 16,
          ),
        ),
        subtitle: Text(
          'Stock: ${product.stock} | Barcode: ${product.barcode}',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
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
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryTeal),
                onPressed: () => onSelected(product),
              )
            else
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
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => ref.read(billingProvider.notifier).updateQuantity(
                        product.id, 
                        quantity - 1, 
                        variantId: product.selectedVariantId
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => ref.read(billingProvider.notifier).updateQuantity(
                        product.id, 
                        quantity + 1, 
                        variantId: product.selectedVariantId
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          if (!isInCart) {
            onSelected(product);
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
    return Container(
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
            child: item.product.photo != null && item.product.photo!.isNotEmpty
                ? Image.memory(
                    base64Decode(item.product.photo!.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.image_not_supported_outlined, size: 20),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryTeal),
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
                  '₹${item.price.toStringAsFixed(2)}${item.product.uom.isNotEmpty ? ' / ${item.product.uom}' : ''}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove, size: 18, color: Theme.of(context).iconTheme.color),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => ref.read(billingProvider.notifier).updateQuantity(item.product.id, item.quantity - 1, variantId: item.product.selectedVariantId),
                ),
                Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 18, color: Theme.of(context).iconTheme.color),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => ref.read(billingProvider.notifier).updateQuantity(item.product.id, item.quantity + 1, variantId: item.product.selectedVariantId),
                ),
              ],
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
    );
  }
}
