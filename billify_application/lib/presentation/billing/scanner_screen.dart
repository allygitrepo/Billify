import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/presentation/billing/thermal_invoice_dialog.dart';
import 'package:billify_application/presentation/product/add_product_screen.dart';
import 'package:billify_application/providers/billing_provider.dart';
import 'package:billify_application/providers/business_provider.dart';
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
      _controller.stop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProductScreen(initialBarcode: barcode),
        ),
      ).then((_) {
        _resumeScanner();
      });
    }
  }

  void _resumeScanner() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller.start();
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

    final taxPercent = currentBusiness.tax;
    final gstPercent = currentBusiness.gst;
    final invoiceNo = '${currentBusiness.invoicePrefix}${currentBusiness.nextInvoiceNumber}';

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

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final businessState = ref.watch(businessProvider);
    final business = businessState.currentBusiness;
    final taxPercent = business?.tax ?? 0.0;
    final gstPercent = business?.gst ?? 0.0;

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Product')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout Terminal'),
        actions: [
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
              color: AppTheme.softGrey.withOpacity(0.5),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scanned Items (${billingState.items.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          'Total: ₹${billingState.getTotal(taxPercent, gstPercent).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: billingState.items.isEmpty
                        ? const Center(
                            child: Text('No items scanned yet', style: TextStyle(color: Colors.grey)),
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
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
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

class _PanelItemTile extends ConsumerWidget {
  final dynamic item;

  const _PanelItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Colors.black),
                  onPressed: () => ref.read(billingProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  onPressed: () => ref.read(billingProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
