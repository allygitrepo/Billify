import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/validators.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/data/models/uom_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/custom_text_field.dart';
import 'package:billify_application/providers/category_provider.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:billify_application/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

class ProductManagementPage extends ConsumerStatefulWidget {
  final String? initialBarcode;

  const ProductManagementPage({
    super.key,
    this.initialBarcode,
  });

  @override
  ConsumerState<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends ConsumerState<ProductManagementPage> {
  @override
  void initState() {
    super.initState();
    // If initial barcode is passed (from scanner), open bottom sheet immediately
    if (widget.initialBarcode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProductBottomSheet(barcode: widget.initialBarcode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productList = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
      ),
      body: productList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No products added yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productList.length,
              itemBuilder: (context, index) {
                final product = productList[index];
                return _ProductListTile(
                  product: product,
                  onEdit: () => _showProductBottomSheet(product: product),
                  onDelete: () => _showDeleteDialog(product),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductBottomSheet(),
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showProductBottomSheet({ProductModel? product, String? barcode}) {
    final formKey = GlobalKey<FormState>();
    final barcodeController = TextEditingController(text: product?.barcode ?? barcode ?? '');
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '1');
    
    String? selectedCategoryId = product?.categoryId;
    String selectedUomId = product?.uomId ?? 'pcs';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      product == null ? 'Add Product' : 'Edit Product',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: barcodeController,
                      label: 'Barcode',
                      hint: 'Scan or enter barcode',
                      prefixIcon: Icons.qr_code_scanner,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryTeal),
                        onPressed: () async {
                          final result = await _showScannerBottomSheet();
                          if (result != null) {
                            barcodeController.text = result;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: nameController,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      prefixIcon: Icons.shopping_bag_outlined,
                      validator: (v) => Validators.validateRequired(v, 'Product Name'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: priceController,
                            label: 'Price',
                            hint: '0.00',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.attach_money,
                            validator: (v) => Validators.validateRequired(v, 'Price'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: stockController,
                            label: product == null ? 'Opening Stock' : 'Opening Stock (Locked)',
                            hint: '0',
                            enabled: product == null, // Only editable on creation
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.inventory_2_outlined,
                            suffixIcon: product != null 
                              ? const Tooltip(
                                  message: 'Opening stock cannot be changed. Use Stock Management to adjust current stock.',
                                  child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                )
                              : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(
                      initialValue: selectedCategoryId,
                      onChanged: (val) => setSheetState(() => selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),
                    _buildUomDropdown(
                      initialValue: selectedUomId,
                      onChanged: (val) => setSheetState(() => selectedUomId = val ?? 'pcs'),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: product == null ? 'ADD PRODUCT' : 'UPDATE PRODUCT',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          setSheetState(() => isSaving = true);
                          
                          final newProduct = ProductModel(
                            id: product?.id ?? const Uuid().v4(),
                            barcode: barcodeController.text,
                            name: nameController.text,
                            price: double.tryParse(priceController.text) ?? 0.0,
                            stock: int.tryParse(stockController.text) ?? 0,
                            categoryId: selectedCategoryId,
                            uomId: selectedUomId,
                          );

                          await ref.read(productProvider.notifier).saveProduct(newProduct);
                          
                          if (context.mounted) {
                            Navigator.pop(context, newProduct);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(product == null ? 'Product saved' : 'Product updated')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showScannerBottomSheet() async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Scan Barcode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first.rawValue;
                    if (barcode != null) Navigator.pop(context, barcode);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({String? initialValue, required Function(String?) onChanged}) {
    final categories = ref.watch(categoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: initialValue,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_outlined),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          hint: const Text('Select category'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('None'),
            ),
            ...categories.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name),
            )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildUomDropdown({required String initialValue, required Function(String?) onChanged}) {
    final uoms = ref.watch(uomProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit of Measure (UOM)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: initialValue,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.straighten),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: uoms.map((u) => DropdownMenuItem(
            value: u.id,
            child: Text(u.name),
          )).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Select UOM' : null,
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(productProvider.notifier).deleteProduct(product.id);
    }
  }
}

class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryTeal),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final uoms = ref.watch(uomProvider);
                final uom = uoms.firstWhere(
                  (u) => u.id == product.uomId, 
                  orElse: () => UomModel(id: product.uomId, name: product.uomId)
                );
                return Text('Price: ₹${product.price} | Stock: ${product.stock} ${uom.name}');
              },
            ),
            if (product.barcode.isNotEmpty)
              Text('Code: ${product.barcode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
