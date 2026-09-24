import 'dart:convert';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

class ProductFormBottomSheet extends ConsumerStatefulWidget {
  final ProductModel? product;
  final String? initialBarcode;

  const ProductFormBottomSheet({
    super.key,
    this.product,
    this.initialBarcode,
  });

  static Future<ProductModel?> show(
    BuildContext context, {
    ProductModel? product,
    String? barcode,
  }) {
    return showModalBottomSheet<ProductModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormBottomSheet(
        product: product,
        initialBarcode: barcode,
      ),
    );
  }

  @override
  ConsumerState<ProductFormBottomSheet> createState() =>
      _ProductFormBottomSheetState();
}

class _ProductFormBottomSheetState
    extends ConsumerState<ProductFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _pricePerUnitController;

  String? _selectedCategoryId;
  String _selectedUomId = 'pcs';
  String? _base64Image;
  bool _hasVariants = false;
  List<ProductVariantModel> _variants = [];
  bool _isWeighted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _barcodeController = TextEditingController(
      text: p?.barcode ?? widget.initialBarcode ?? '',
    );
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null && p.basePrice != 0 ? p.basePrice.toString() : '',
    );
    _stockController = TextEditingController(
      text: p != null && p.openingStock != 0 ? p.openingStock.toString() : '',
    );

    _isWeighted = p?.is_weighted ?? false;
    _pricePerUnitController = TextEditingController(
      text: p?.price_per_unit != null && p!.price_per_unit > 0
          ? p.price_per_unit.toString()
          : (_isWeighted ? p?.basePrice.toString() ?? '' : ''),
    );

    _selectedCategoryId = p?.category_id;
    _base64Image = p?.photo;
    _hasVariants = p?.hasVariants ?? false;
    _variants = p?.variants != null ? List.from(p!.variants) : [];

    // Resolve initial UOM
    _selectedUomId = p?.uom ?? 'pcs';
    final currentUoms = ref.read(uomProvider);
    if (currentUoms.isNotEmpty &&
        !currentUoms.any((u) => u.id == _selectedUomId)) {
      final fallback = currentUoms
          .where(
            (u) =>
                u.shortCode.toLowerCase() == _selectedUomId.toLowerCase() ||
                u.name.toLowerCase() == _selectedUomId.toLowerCase(),
          )
          .firstOrNull;
      if (fallback != null) {
        _selectedUomId = fallback.id;
      } else if (p == null) {
        final pcsUom = currentUoms
            .where(
              (u) =>
                  u.shortCode.toLowerCase() == 'pcs' ||
                  u.name.toLowerCase() == 'pieces',
            )
            .firstOrNull;
        if (pcsUom != null) {
          _selectedUomId = pcsUom.id;
        } else if (currentUoms.isNotEmpty) {
          _selectedUomId = currentUoms.first.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _pricePerUnitController.dispose();
    super.dispose();
  }

  Future<String?> _showScannerBottomSheet() async {
    return await showModalBottomSheet<String>(
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Scan Product Barcode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final p = widget.product;
      final newProduct = ProductModel(
        id: p?.id ?? const Uuid().v4(),
        barcode: _hasVariants ? '' : _barcodeController.text,
        basePrice: _hasVariants || _isWeighted
            ? 0.0
            : (double.tryParse(_priceController.text) ?? 0.0),
        price_per_unit: _isWeighted
            ? (double.tryParse(_pricePerUnitController.text) ?? 0.0)
            : 0.0,
        openingStock: _hasVariants
            ? 0.0
            : (double.tryParse(_stockController.text) ?? 0.0),
        currentStock: _hasVariants
            ? 0.0
            : (p?.currentStock ??
                (double.tryParse(_stockController.text) ?? 0.0)),
        category_id: _selectedCategoryId,
        uom: _selectedUomId,
        photo: _base64Image,
        hasVariants: _hasVariants,
        variants: _hasVariants ? _variants : [],
        is_weighted: _isWeighted,
        base_uom_id: int.tryParse(_selectedUomId),
        name: _nameController.text,
      );

      AppFeedback.unfocus();
      await ref.read(productProvider.notifier).saveProduct(newProduct);

      if (mounted) {
        Navigator.pop(context, newProduct);
        AppFeedback.showSuccess(
          context,
          widget.product == null ? 'Product added successfully' : 'Product updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to save product: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(featureSettingsProvider);
    final categories = ref.watch(categoryProvider);
    final uoms = ref.watch(uomProvider);

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
            key: _formKey,
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
                      widget.product == null ? 'Add Product' : 'Edit Product',
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
                          setState(() => _base64Image = base64Encode(bytes));
                        }
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppTheme.primaryTeal.withOpacity(0.1),
                        backgroundImage: _base64Image != null
                            ? MemoryImage(
                                ImageUtils.decodeBase64(_base64Image!),
                              )
                            : null,
                        child: _base64Image == null
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
                  controller: _nameController,
                  label: 'Product Name',
                  hint: 'Enter product name',
                  prefixIcon: Icons.shopping_bag_outlined,
                  validator: (v) =>
                      Validators.validateRequired(v, 'Product Name'),
                ),
                const SizedBox(height: 16),
                if (settings.isCategoryEnabled) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Category'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  value: _selectedUomId,
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
                    if (val != null) setState(() => _selectedUomId = val);
                  },
                ),
                const SizedBox(height: 16),
                if (settings.isVariantsEnabled && !_isWeighted) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _hasVariants,
                        activeColor: AppTheme.primaryTeal,
                        onChanged: (val) =>
                            setState(() => _hasVariants = val ?? false),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Packaged'),
                        value: false,
                        groupValue: _isWeighted,
                        activeColor: AppTheme.primaryTeal,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() {
                          _isWeighted = val!;
                          if (_isWeighted) _hasVariants = false;
                        }),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Loose / Weighted'),
                        value: true,
                        groupValue: _isWeighted,
                        activeColor: AppTheme.primaryTeal,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() {
                          _isWeighted = val!;
                          if (_isWeighted) _hasVariants = false;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_hasVariants) ...[
                  CustomTextField(
                    controller: _barcodeController,
                    label: 'Barcode (Optional)',
                    hint: 'Scan or enter barcode (leave empty if none)',
                    prefixIcon: Icons.qr_code_scanner,
                    validator: (v) => Validators.validateBarcode(v, isOptional: true),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppTheme.primaryTeal,
                      ),
                      onPressed: () async {
                        final result = await _showScannerBottomSheet();
                        if (result != null) {
                          _barcodeController.text = result;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _isWeighted
                        ? _pricePerUnitController
                        : _priceController,
                    label: _isWeighted ? 'Price per Unit' : 'Price',
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                    validator: (v) => Validators.validatePrice(
                      v,
                      fieldName: _isWeighted ? 'Price per Unit' : 'Price',
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _stockController,
                    label: widget.product == null
                        ? 'Opening Stock'
                        : 'Opening Stock (Locked)',
                    hint: '0',
                    enabled: widget.product == null,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.inventory_2_outlined,
                    validator: (v) => Validators.validateStock(
                      v,
                      isWeighted: _isWeighted,
                      isRequired: false,
                    ),
                  ),
                ] else ...[
                  // Variants List Editor
                  const Text(
                    'Variants',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ..._variants.asMap().entries.map((entry) {
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
                                  label: 'Variant Name',
                                  hint: 'XL, Red, etc.',
                                  initialValue: variant.name,
                                  validator: (v) =>
                                      Validators.validateRequired(
                                        v,
                                        'Variant Name',
                                      ),
                                  onChanged: (v) => _variants[idx] =
                                      _variants[idx].copyWith(name: v),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => setState(
                                  () => _variants.removeAt(idx),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Barcode',
                                  hint: 'SKU / Barcode',
                                  initialValue: variant.sku,
                                  validator: (v) => Validators.validateBarcode(
                                    v,
                                    isOptional: true,
                                  ),
                                  onChanged: (v) => _variants[idx] =
                                      _variants[idx].copyWith(sku: v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Price',
                                  keyboardType: TextInputType.number,
                                  initialValue: variant.price != 0
                                      ? variant.price.toString()
                                      : '',
                                  onChanged: (v) => _variants[idx] =
                                      _variants[idx].copyWith(
                                        price: double.tryParse(v),
                                      ),
                                  validator: (v) => Validators.validatePrice(
                                    v,
                                    fieldName: 'Variant Price',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Stock',
                                  keyboardType: TextInputType.number,
                                  initialValue: variant.openingStock != 0
                                      ? variant.openingStock.toString()
                                      : '',
                                  enabled: widget.product == null ||
                                      variant.id.length > 10,
                                  validator: (v) => Validators.validateStock(
                                    v,
                                    isRequired: false,
                                  ),
                                  onChanged: (v) => _variants[idx] =
                                      _variants[idx].copyWith(
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
                    onPressed: () => setState(
                      () => _variants.add(ProductVariantModel.empty()),
                    ),
                    icon: const Icon(Icons.add, color: AppTheme.primaryTeal),
                    label: const Text(
                      'Add Variant',
                      style: TextStyle(color: AppTheme.primaryTeal),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  text: widget.product == null
                      ? 'ADD PRODUCT'
                      : 'UPDATE PRODUCT',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
