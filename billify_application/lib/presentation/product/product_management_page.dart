import 'dart:convert';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/validators.dart';
import 'package:billify_application/data/models/product_model.dart';
import 'package:billify_application/data/models/product_variant_model.dart';
import 'package:billify_application/data/models/uom_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/custom_text_field.dart';
import 'package:billify_application/providers/category_provider.dart';
import 'package:billify_application/providers/feature_settings_provider.dart';
import 'package:billify_application/providers/product_provider.dart';
import 'package:billify_application/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


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
    final categories = ref.watch(categoryProvider);

    // Filter products
    final filteredProducts = productList.where((product) {
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.barcode.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesCategory = _selectedCategoryId == null || 
          product.category_id == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onChanged: (_) => setState(() {}), // Trigger filter
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    decoration: InputDecoration(

                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      hintText: 'Category',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          productList.isEmpty 
                            ? 'No products added yet' 
                            : 'No products match your search', 
                          style: const TextStyle(color: Colors.grey)
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _ProductListTile(
                        product: product,
                        onEdit: () => _showProductBottomSheet(product: product),
                        onDelete: () => _showDeleteDialog(product),
                      );
                    },
                  ),
          ),
        ],
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
    final priceController = TextEditingController(text: product?.basePrice.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '1');
    
    String? selectedCategoryId = product?.category_id;
    String selectedUomId = product?.uom ?? 'pcs';
    String? base64Image = product?.photo;
    bool hasVariants = product?.hasVariants ?? false;
    List<ProductVariantModel> variants = product?.variants != null ? List.from(product!.variants) : [];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final settings = ref.watch(featureSettingsProvider);
          
          return Container(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product == null ? 'Add Product' : 'Edit Product',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 70);
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setSheetState(() => base64Image = base64Encode(bytes));
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                              backgroundImage: base64Image != null ? MemoryImage(base64Decode(base64Image!)) : null,
                              child: base64Image == null ? const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryTeal) : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: nameController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        prefixIcon: Icons.shopping_bag_outlined,
                        validator: (v) => Validators.validateRequired(v, 'Product Name'),
                      ),
                      const SizedBox(height: 16),
                      if (settings.isCategoryEnabled) ...[
                        _buildCategoryDropdown(
                          initialValue: selectedCategoryId,
                          onChanged: (val) => setSheetState(() => selectedCategoryId = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildUomDropdown(
                        initialValue: selectedUomId,
                        onChanged: (val) => setSheetState(() => selectedUomId = val ?? 'pcs'),
                      ),
                      const SizedBox(height: 16),
                      if (settings.isVariantsEnabled) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: hasVariants,
                              activeColor: AppTheme.primaryTeal,
                              onChanged: (val) => setSheetState(() => hasVariants = val ?? false),
                            ),
                            const Text('This product has variants', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!hasVariants) ...[
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
                      ] else ...[
                        const Text('Variants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...variants.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final variant = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: CustomTextField(
                                          label: 'Variant Name (Size/Color)',
                                          hint: 'XL, Red, etc.',
                                          initialValue: variant.name,
                                          validator: (v) => Validators.validateRequired(v, 'Variant Name'),
                                          onChanged: (v) => variants[idx] = variants[idx].copyWith(name: v),
                                        ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => setSheetState(() => variants.removeAt(idx)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        key: ValueKey('barcode_${variant.id}_${variant.sku}'),
                                        label: 'Barcode',
                                        initialValue: variant.sku,
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.qr_code_scanner, size: 18, color: AppTheme.primaryTeal),
                                          onPressed: () async {
                                            final result = await _showScannerBottomSheet();
                                            if (result != null) {
                                              setSheetState(() => variants[idx] = variants[idx].copyWith(sku: result));
                                            }
                                          },
                                        ),
                                        onChanged: (v) => variants[idx] = variants[idx].copyWith(sku: v),
                                        validator: (v) => Validators.validateRequired(v, 'Barcode'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Price',
                                        keyboardType: TextInputType.number,
                                        initialValue: variant.price.toString(),
                                        onChanged: (v) => variants[idx] = variants[idx].copyWith(price: double.tryParse(v) ?? 0.0),
                                        validator: (v) => Validators.validateRequired(v, 'Price'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Stock',
                                        keyboardType: TextInputType.number,
                                        initialValue: variant.stock.toString(),
                                        enabled: product == null,
                                        onChanged: (v) => variants[idx] = variants[idx].copyWith(stock: int.tryParse(v) ?? 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        TextButton.icon(
                          onPressed: () => setSheetState(() => variants.add(ProductVariantModel.empty())),
                          icon: const Icon(Icons.add, color: AppTheme.primaryTeal),
                          label: const Text('Add Variant', style: TextStyle(color: AppTheme.primaryTeal)),
                        ),
                      ],
                      const SizedBox(height: 32),
                      CustomButton(
                        text: product == null ? 'ADD PRODUCT' : 'UPDATE PRODUCT',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isSaving = true);
                            
                            final newProduct = ProductModel(
                              id: product?.id ?? const Uuid().v4(),
                              barcode: hasVariants ? '' : barcodeController.text,
                              name: nameController.text,
                              basePrice: hasVariants ? 0.0 : (double.tryParse(priceController.text) ?? 0.0),
                              stock: hasVariants ? 0 : (int.tryParse(stockController.text) ?? 0),
                              category_id: selectedCategoryId,
                              uom: selectedUomId,
                              photo: base64Image,
                              hasVariants: hasVariants,
                              variants: hasVariants ? variants : [],
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
          );
        },
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
            image: product.photo != null 
              ? DecorationImage(
                  image: MemoryImage(base64Decode(product.photo!)),
                  fit: BoxFit.cover,
                )
              : null,
          ),
          child: product.photo == null 
            ? const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryTeal) 
            : null,
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.hasVariants)
              Text('${product.variants.length} Variants', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w500))
            else
              Consumer(
                builder: (context, ref, child) {
                  final uoms = ref.watch(uomProvider);
                  final uom = uoms.firstWhere(
                    (u) => u.id == product.uom, 
                    orElse: () => UomModel(id: product.uom, name: product.uom)
                  );
                  return Text('Price: ₹${product.basePrice} | Stock: ${product.stock} ${uom.name}');
                },
              ),
            if (!product.hasVariants && product.barcode.isNotEmpty)
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
