import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/validators.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/custom_text_field.dart';
import 'package:billify_application/presentation/widgets/section_card.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;
  final ProductModel? existingProduct;

  const AddProductScreen({
    super.key,
    this.initialBarcode,
    this.existingProduct,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  
  ProductModel? _editingProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      _setEditingProduct(widget.existingProduct!);
    } else if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
      _stockController.text = '1';
    } else {
      _stockController.text = '1';
    }
  }

  void _setEditingProduct(ProductModel product) {
    setState(() {
      _editingProduct = product;
    });
    _barcodeController.text = product.barcode;
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _unitController.text = product.unit ?? '';
  }

  void _clearForm() {
    setState(() {
      _editingProduct = null;
    });
    _barcodeController.clear();
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _unitController.clear();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final product = ProductModel(
        id: _editingProduct?.id ?? const Uuid().v4(),
        barcode: _barcodeController.text,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
      );

      await ref.read(productProvider.notifier).saveProduct(product);
      
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingProduct == null ? 'Product saved' : 'Product updated')),
        );
        if (widget.initialBarcode != null) {
          Navigator.pop(context, product);
        } else {
          _clearForm();
        }
      }
    }
  }

  Future<void> _showScannerDialog() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Scan Barcode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

    if (result != null) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productList = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingProduct == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (_editingProduct != null || _barcodeController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearForm,
              tooltip: 'Clear Form',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _barcodeController,
                      label: 'Barcode',
                      hint: 'Scan or enter barcode',
                      prefixIcon: Icons.qr_code_scanner,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryTeal),
                        onPressed: _showScannerDialog,
                      ),
                      validator: (v) => Validators.validateRequired(v, 'Barcode'),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      prefixIcon: Icons.shopping_bag_outlined,
                      validator: (v) => Validators.validateRequired(v, 'Product Name'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _priceController,
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
                            controller: _stockController,
                            label: 'Stock',
                            hint: '0',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.inventory_2_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _unitController,
                      label: 'Unit (Optional)',
                      hint: 'e.g. kg, pcs, box',
                      prefixIcon: Icons.straighten,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _editingProduct == null ? 'ADD PRODUCT' : 'UPDATE PRODUCT',
                onPressed: _handleSave,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
              const Text(
                'Registered Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (productList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No products added yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    return _ProductListTile(
                      product: product,
                      onEdit: () => _setEditingProduct(product),
                      onDelete: () => _showDeleteDialog(product),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
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
            Text('Price: ₹${product.price} | Stock: ${product.stock} ${product.unit ?? ''}'),
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
