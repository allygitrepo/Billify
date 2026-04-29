import 'dart:convert';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/product_variant_model.dart';
import 'package:billify/data/models/uom_model.dart';
import 'package:billify/presentation/widgets/custom_button.dart';
import 'package:billify/presentation/widgets/custom_text_field.dart';
import 'package:billify/providers/category_provider.dart';
import 'package:billify/providers/feature_settings_provider.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:billify/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

class ProductManagementPage extends ConsumerStatefulWidget {
  final String? initialBarcode;

  const ProductManagementPage({super.key, this.initialBarcode});

  @override
  ConsumerState<ProductManagementPage> createState() =>
      _ProductManagementPageState();
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
      final matchesSearch =
          _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          product.barcode.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );

      final matchesCategory =
          _selectedCategoryId == null ||
          product.category_id == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Management')),
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
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      hintText: 'Category',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  () => ref
                      .read(productProvider.notifier)
                      .fetchAndSyncProducts(),
              child:
                  filteredProducts.isEmpty
                      ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    productList.isEmpty
                                        ? 'No products added yet'
                                        : 'No products match your search',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _ProductListTile(
                            product: product,
                            onEdit:
                                () => _showProductBottomSheet(product: product),
                            onDelete: () => _showDeleteDialog(product),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),

      floatingActionButton:
          ref
              .watch(authProvider)
              .hasPermission(PermissionModule.products, PermissionAction.add)
          ? FloatingActionButton(
              onPressed: () => _showProductBottomSheet(),
              backgroundColor: AppTheme.primaryTeal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showProductBottomSheet({ProductModel? product, String? barcode}) {
    final formKey = GlobalKey<FormState>();
    final barcodeController = TextEditingController(
      text: product?.barcode ?? barcode ?? '',
    );
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null && product.basePrice != 0
          ? product.basePrice.toString()
          : '',
    );
    // final purchasePriceController = TextEditingController(text: product?.purchasePrice.toString() ?? '');
    final stockController = TextEditingController(
      text: product != null && product.openingStock != 0
          ? product.openingStock.toString()
          : '',
    );

    String? selectedCategoryId = product?.category_id;

    // Resolve UOM ID
    String selectedUomId = product?.uom ?? 'pcs';
    final currentUoms = ref.read(uomProvider);
    if (currentUoms.isNotEmpty &&
        !currentUoms.any((u) => u.id == selectedUomId)) {
      final fallback = currentUoms
          .where(
            (u) =>
                u.shortCode.toLowerCase() == selectedUomId.toLowerCase() ||
                u.name.toLowerCase() == selectedUomId.toLowerCase(),
          )
          .firstOrNull;

      if (fallback != null) {
        selectedUomId = fallback.id;
      } else if (product == null) {
        // For new products, try to find "Pieces" or "pcs" explicitly
        final pcsUom = currentUoms
            .where(
              (u) =>
                  u.shortCode.toLowerCase() == 'pcs' ||
                  u.name.toLowerCase() == 'pieces',
            )
            .firstOrNull;
        if (pcsUom != null) {
          selectedUomId = pcsUom.id;
        } else if (currentUoms.isNotEmpty) {
          // If not found, use first item but avoid Kilograms if possible for packaged
          selectedUomId = currentUoms.first.id;
        }
      }
    }

    String? base64Image = product?.photo;
    bool hasVariants = product?.hasVariants ?? false;
    List<ProductVariantModel> variants = product?.variants != null
        ? List.from(product!.variants)
        : [];
    bool isWeighted = product?.is_weighted ?? false;
    final pricePerUnitController = TextEditingController(
      text: product?.price_per_unit != null && product!.price_per_unit > 0
          ? product.price_per_unit.toString()
          : (isWeighted ? product?.basePrice.toString() ?? '' : ''),
    );
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                                imageQuality: 70,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setSheetState(
                                  () => base64Image = base64Encode(bytes),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryTeal.withOpacity(
                                0.1,
                              ),
                              backgroundImage: base64Image != null
                                  ? MemoryImage(
                                      ImageUtils.decodeBase64(base64Image!),
                                    )
                                  : null,
                              child: base64Image == null
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppTheme.primaryTeal,
                                    )
                                  : null,
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
                        validator: (v) =>
                            Validators.validateRequired(v, 'Product Name'),
                      ),
                      const SizedBox(height: 16),
                      if (settings.isCategoryEnabled) ...[
                        _buildCategoryDropdown(
                          initialValue: selectedCategoryId,
                          onChanged: (val) =>
                              setSheetState(() => selectedCategoryId = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildUomDropdown(
                        initialValue: selectedUomId,
                        onChanged: (val) =>
                            setSheetState(() => selectedUomId = val ?? 'pcs'),
                      ),
                      const SizedBox(height: 16),
                      if (settings.isVariantsEnabled && !isWeighted) ...[
                        Row(
                          children: [
                            Checkbox(
                              value: hasVariants,
                              activeColor: AppTheme.primaryTeal,
                              onChanged: (val) => setSheetState(
                                () => hasVariants = val ?? false,
                              ),
                            ),
                            const Text(
                              'This product has variants',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Selling Type Selection
                      const Text(
                        'Selling Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Packaged'),
                              value: false,
                              groupValue: isWeighted,
                              activeColor: AppTheme.primaryTeal,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setSheetState(() {
                                isWeighted = val!;
                                if (isWeighted) hasVariants = false;
                              }),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Loose / Weighted'),
                              value: true,
                              groupValue: isWeighted,
                              activeColor: AppTheme.primaryTeal,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setSheetState(() {
                                isWeighted = val!;
                                if (isWeighted) hasVariants = false;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!hasVariants) ...[
                        CustomTextField(
                          controller: barcodeController,
                          label: 'Barcode (Optional)',
                          hint: 'Scan or enter barcode (leave empty if none)',
                          prefixIcon: Icons.qr_code_scanner,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              color: AppTheme.primaryTeal,
                            ),
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
                              flex: 1,
                              child: CustomTextField(
                                controller: isWeighted
                                    ? pricePerUnitController
                                    : priceController,
                                label: isWeighted ? 'Price per Unit' : 'Price',
                                hint: '0.00',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.attach_money,
                                validator: (v) => Validators.validateRequired(
                                  v,
                                  isWeighted ? 'Price per Unit' : 'Price',
                                ),
                              ),
                            ),
                            /*                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: CustomTextField(
                                controller: purchasePriceController,
                                label: 'Cost Price',
                                hint: '0.00',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.shopping_basket_outlined,
                                validator: (v) => Validators.validateRequired(v, 'Cost Price'),
                              ),
                            ),*/
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: stockController,
                                label: product == null
                                    ? 'Opening Stock'
                                    : 'Opening Stock (Locked)',
                                hint: '0',
                                enabled:
                                    product ==
                                    null, // Only editable on creation
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.inventory_2_outlined,
                                suffixIcon: product != null
                                    ? const Tooltip(
                                        message:
                                            'Opening stock cannot be changed. Use Stock Management to adjust current stock.',
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'Variants',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        key: ValueKey('name_${variant.id}'),
                                        label: 'Variant Name (Size/Color)',
                                        hint: 'XL, Red, etc.',
                                        initialValue: variant.name,
                                        validator: (v) =>
                                            Validators.validateRequired(
                                              v,
                                              'Variant Name',
                                            ),
                                        onChanged: (v) => variants[idx] =
                                            variants[idx].copyWith(name: v),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => setSheetState(
                                        () => variants.removeAt(idx),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        key: ValueKey('barcode_${variant.id}'),
                                        label: 'Barcode',
                                        hint: 'Enter or scan barcode',
                                        initialValue: variant.sku,
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.qr_code_scanner,
                                            size: 18,
                                            color: AppTheme.primaryTeal,
                                          ),
                                          onPressed: () async {
                                            final result =
                                                await _showScannerBottomSheet();
                                            if (result != null) {
                                              setSheetState(
                                                () => variants[idx] =
                                                    variants[idx].copyWith(
                                                      sku: result,
                                                    ),
                                              );
                                            }
                                          },
                                        ),
                                        onChanged: (v) => variants[idx] =
                                            variants[idx].copyWith(sku: v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextField(
                                        key: ValueKey('price_${variant.id}'),
                                        label: 'Price',
                                        keyboardType: TextInputType.number,
                                        initialValue: variant.price != 0
                                            ? variant.price.toString()
                                            : '',
                                        onChanged: (v) => variants[idx] =
                                            variants[idx].copyWith(
                                              price: double.tryParse(v),
                                            ),
                                        validator: (v) =>
                                            Validators.validateRequired(
                                              v,
                                              'Price',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextField(
                                        key: ValueKey('stock_${variant.id}'),
                                        label: 'Stock',
                                        keyboardType: TextInputType.number,
                                        initialValue: variant.openingStock != 0
                                            ? variant.openingStock.toString()
                                            : '',
                                        enabled:
                                            product == null ||
                                            variant.id.length > 10,
                                        onChanged: (v) => variants[idx] =
                                            variants[idx].copyWith(
                                              openingStock:
                                                  double.tryParse(v) ?? 0,
                                              currentStock:
                                                  double.tryParse(v) ?? 0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        TextButton.icon(
                          onPressed: () => setSheetState(
                            () => variants.add(ProductVariantModel.empty()),
                          ),
                          icon: const Icon(
                            Icons.add,
                            color: AppTheme.primaryTeal,
                          ),
                          label: const Text(
                            'Add Variant',
                            style: TextStyle(color: AppTheme.primaryTeal),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      CustomButton(
                        text: product == null
                            ? 'ADD PRODUCT'
                            : 'UPDATE PRODUCT',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isSaving = true);

                            final newProduct = ProductModel(
                              id: product?.id ?? const Uuid().v4(),
                              barcode: hasVariants
                                  ? ''
                                  : barcodeController.text,
                              basePrice: hasVariants || isWeighted
                                  ? 0.0
                                  : (double.tryParse(priceController.text) ??
                                        0.0),
                              price_per_unit: isWeighted
                                  ? (double.tryParse(
                                          pricePerUnitController.text,
                                        ) ??
                                        0.0)
                                  : 0.0,
                              openingStock: hasVariants
                                  ? 0.0
                                  : (double.tryParse(stockController.text) ??
                                        0.0),
                              currentStock: hasVariants
                                  ? 0.0
                                  : (product?.currentStock ??
                                        (double.tryParse(
                                              stockController.text,
                                            ) ??
                                            0.0)),
                              category_id: selectedCategoryId,
                              uom: selectedUomId,
                              photo: base64Image,
                              hasVariants: hasVariants,
                              variants: hasVariants ? variants : [],
                              is_weighted: isWeighted,
                              base_uom_id: int.tryParse(selectedUomId),
                              name: nameController.text,
                            );

                            await ref
                                .read(productProvider.notifier)
                                .saveProduct(newProduct);

                            if (context.mounted) {
                              Navigator.pop(context, newProduct);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    product == null
                                        ? 'Product saved'
                                        : 'Product updated',
                                  ),
                                ),
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
              child: Text(
                'Scan Barcode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
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

  Widget _buildCategoryDropdown({
    String? initialValue,
    required Function(String?) onChanged,
  }) {
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          hint: const Text('Select category'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('None')),
            ...categories.map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildUomDropdown({
    required String initialValue,
    required Function(String?) onChanged,
  }) {
    final uoms = ref.watch(uomProvider);

    // Safety check: ensure initialValue exists in uoms list to avoid assertion error
    String? dropdownValue = initialValue;
    if (uoms.isNotEmpty && !uoms.any((u) => u.id == dropdownValue)) {
      // Try to find by name or shortCode as fallback, otherwise default to first item or null
      final fallback = uoms
          .where((u) => u.shortCode == initialValue || u.name == initialValue)
          .firstOrNull;
      dropdownValue = fallback?.id ?? (uoms.isNotEmpty ? uoms.first.id : null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit of Measure (UOM)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: dropdownValue,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.straighten),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: uoms
              .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
              .toList(),
          onChanged: (val) {
            onChanged(val);
          },
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
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

class _ProductListTile extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    image: MemoryImage(ImageUtils.decodeBase64(product.photo!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.photo == null
              ? const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.primaryTeal,
                )
              : null,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.hasVariants)
              Text(
                '${product.variants.length} Variants',
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Consumer(
                builder: (context, ref, child) {
                  final uoms = ref.watch(uomProvider);
                  final uom = uoms.firstWhere(
                    (u) => u.id == product.uom,
                    orElse: () => UomModel(
                      id: product.uom,
                      name: product.uom,
                      shortCode: product.uom,
                    ),
                  );
                  return Text(
                    '${product.is_weighted ? "Price/Unit" : "Price"}: ₹${product.basePrice} | Stock: ${product.stock} ${uom.name}',
                  );
                },
              ),
            if (!product.hasVariants && product.barcode.isNotEmpty)
              Text(
                'Code: ${product.barcode}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ref
                .watch(authProvider)
                .hasPermission(
                  PermissionModule.products,
                  PermissionAction.update,
                ))
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
            if (ref
                .watch(authProvider)
                .hasPermission(
                  PermissionModule.products,
                  PermissionAction.delete,
                ))
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
