import 'dart:convert';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/data/models/category_model.dart';
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ProductFormBottomSheet(
            product: product,
            initialBarcode: barcode,
          ),
        ),
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
    String formatNum(double? val) {
      if (val == null || val == 0) return '';
      return val % 1 == 0 ? val.toInt().toString() : val.toString();
    }

    _priceController = TextEditingController(
      text: p != null ? formatNum(p.basePrice) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? formatNum(p.openingStock) : '',
    );

    _isWeighted = p?.is_weighted ?? false;
    _pricePerUnitController = TextEditingController(
      text: p?.price_per_unit != null && p!.price_per_unit > 0
          ? formatNum(p.price_per_unit)
          : (_isWeighted ? (p != null ? formatNum(p.basePrice) : '') : ''),
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              bottom: true,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Scan Barcode',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: MobileScanner(
                          onDetect: (capture) {
                            final barcode = capture.barcodes.first.rawValue;
                            if (barcode != null && barcode.isNotEmpty) {
                              Navigator.pop(context, barcode);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVariantBottomSheet({ProductVariantModel? variant, int? index}) {
    final variantFormKey = GlobalKey<FormState>();
    final isEditing = variant != null && index != null;

    final nameController = TextEditingController(text: variant?.name ?? '');
    final skuController = TextEditingController(text: variant?.sku ?? '');

    String formatNum(double? val) {
      if (val == null || val == 0) return '';
      return val % 1 == 0 ? val.toInt().toString() : val.toString();
    }

    final priceController = TextEditingController(
      text: variant != null ? formatNum(variant.price) : '',
    );
    final stockController = TextEditingController(
      text: variant != null ? formatNum(variant.openingStock) : '',
    );

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: Theme.of(bottomSheetContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: variantFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEditing ? 'Edit Variant' : 'Add New Variant',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    Navigator.pop(bottomSheetContext),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            controller: nameController,
                            label: 'Variant Name *',
                            hint: 'e.g. 500ml, Red, XL, 1 Kg Pack',
                            isRequired: true,
                            autofocus: !isEditing,
                            validator: (v) => Validators.validateRequired(
                              v,
                              'Variant Name',
                            ),
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            controller: skuController,
                            label: 'Barcode / SKU (Optional)',
                            hint: 'Scan or type barcode',
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner,
                                color: AppTheme.primaryTeal,
                              ),
                              tooltip: 'Scan Barcode',
                              onPressed: () async {
                                final scanned = await _showScannerBottomSheet();
                                if (scanned != null && scanned.isNotEmpty) {
                                  skuController.text = scanned;
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: priceController,
                                  label: _isWeighted
                                      ? 'Price/Unit *'
                                      : 'Variant Price *',
                                  hint: '0.00',
                                  isRequired: true,
                                  prefixIcon: Icons.currency_rupee,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (v) => Validators.validatePrice(
                                    v,
                                    fieldName: _isWeighted
                                        ? 'Variant Price per Unit'
                                        : 'Variant Price',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CustomTextField(
                                  controller: stockController,
                                  label: 'Stock Quantity',
                                  hint: '0',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  enabled: widget.product == null ||
                                      (variant != null &&
                                          variant.id.length > 10) ||
                                      variant == null,
                                  validator: (widget.product == null ||
                                          (variant != null &&
                                              variant.id.length > 10) ||
                                          variant == null)
                                      ? (v) => Validators.validateStock(
                                            v,
                                            isWeighted: _isWeighted,
                                            isRequired: false,
                                          )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          CustomButton(
                            text: isEditing ? 'UPDATE VARIANT' : 'ADD VARIANT',
                            onPressed: () {
                              if (!variantFormKey.currentState!.validate()) return;
                              final price =
                                  double.tryParse(priceController.text) ?? 0.0;
                              final stock =
                                  double.tryParse(stockController.text) ?? 0.0;

                              setState(() {
                                if (isEditing) {
                                  _variants[index] = variant.copyWith(
                                    name: nameController.text.trim(),
                                    sku: skuController.text.trim(),
                                    price: price,
                                    openingStock: stock,
                                    currentStock: stock,
                                  );
                                } else {
                                  _variants.add(
                                    ProductVariantModel(
                                      id: const Uuid().v4(),
                                      name: nameController.text.trim(),
                                      sku: skuController.text.trim(),
                                      price: price,
                                      openingStock: stock,
                                      currentStock: stock,
                                      uom: _selectedUomId,
                                    ),
                                  );
                                }
                              });

                              Navigator.pop(bottomSheetContext);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    if (_hasVariants && _variants.isEmpty) {
      AppFeedback.showError(
        context,
        'Please add at least one variant before saving',
      );
      return;
    }

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
            : (p?.openingStock ??
                (double.tryParse(_stockController.text) ?? 0.0)),
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
        AppFeedback.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleDelete() {
    if (widget.product == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.product!.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(widget.product!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(featureSettingsProvider);
    final categories = ref.watch(categoryProvider);
    final uoms = ref.watch(uomProvider);

    // 1. Prepare unique, de-duplicated categories
    final uniqueCategoriesMap = <String, CategoryModel>{};
    for (final c in categories) {
      if (c.id.isNotEmpty) {
        uniqueCategoriesMap[c.id] = c;
      }
    }
    final categoryList = uniqueCategoriesMap.values.toList();
    final effectiveCategoryId =
        (categoryList.any((c) => c.id == _selectedCategoryId))
            ? _selectedCategoryId
            : null;

    // 2. Prepare unique, de-duplicated UOMs
    final uniqueUomsMap = <String, UomModel>{};
    for (final u in uoms) {
      if (u.id.isNotEmpty && !uniqueUomsMap.containsKey(u.id)) {
        uniqueUomsMap[u.id] = u;
      }
    }

    if (uniqueUomsMap.isEmpty) {
      uniqueUomsMap['pcs'] =
          UomModel(id: 'pcs', name: 'Pieces', shortCode: 'pcs');
      uniqueUomsMap['kg'] =
          UomModel(id: 'kg', name: 'Kilograms', shortCode: 'kg');
      uniqueUomsMap['litre'] =
          UomModel(id: 'litre', name: 'Litres', shortCode: 'ltr');
    }

    // Resolve matching UOM for _selectedUomId
    String effectiveUomId = _selectedUomId;
    if (!uniqueUomsMap.containsKey(effectiveUomId)) {
      final match = uniqueUomsMap.values.where((u) =>
          u.shortCode.toLowerCase() == _selectedUomId.toLowerCase() ||
          u.name.toLowerCase() == _selectedUomId.toLowerCase() ||
          u.id.toLowerCase() == _selectedUomId.toLowerCase()).firstOrNull;
      if (match != null) {
        effectiveUomId = match.id;
      } else if (uniqueUomsMap.isNotEmpty) {
        effectiveUomId = uniqueUomsMap.keys.first;
      } else {
        uniqueUomsMap[effectiveUomId] = UomModel(
          id: effectiveUomId,
          name: effectiveUomId.toUpperCase(),
          shortCode: effectiveUomId,
        );
      }
    }

    final uomList = uniqueUomsMap.values.toList();

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
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
                    Row(
                      children: [
                        Text(
                          widget.product == null ? 'Add Product' : 'Edit Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.product != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Product',
                            onPressed: _isSaving ? null : _handleDelete,
                          ),
                        ],
                      ],
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
                    key: ValueKey('category_dropdown_${effectiveCategoryId}_${categoryList.length}'),
                    value: effectiveCategoryId,
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
                      ...categoryList.map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  key: ValueKey('uom_dropdown_${effectiveUomId}_${uomList.length}'),
                  value: effectiveUomId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.straighten),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: uomList
                      .map((u) => DropdownMenuItem<String>(
                            value: u.id,
                            child: Text(u.name.isNotEmpty ? u.name : u.shortCode),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUomId = val);
                  },
                ),
                const SizedBox(height: 16),
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
                          _isWeighted = val ?? false;
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
                          _isWeighted = val ?? true;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (settings.isVariantsEnabled) ...[
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
                    prefixIcon: Icons.currency_rupee,
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
                    validator: widget.product == null
                        ? (v) => Validators.validateStock(
                              v,
                              isWeighted: _isWeighted,
                              isRequired: false,
                            )
                        : null,
                  ),
                ] else ...[
                  // Variants List Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isWeighted ? 'Variants (Loose / Weighted)' : 'Product Variants',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${_variants.length} ${_variants.length == 1 ? 'Variant' : 'Variants'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_variants.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No variants added yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ Add Variant" below to add variants with custom prices, stock, and barcodes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._variants.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final variant = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showVariantBottomSheet(
                            variant: variant,
                            index: idx,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.style_outlined,
                                      color: AppTheme.primaryTeal,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        variant.name.isNotEmpty ? variant.name : 'Unnamed Variant',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryTeal.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '₹${variant.price % 1 == 0 ? variant.price.toInt() : variant.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: AppTheme.primaryTeal,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          if (variant.sku.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.qr_code,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    variant.sku,
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Stock: ${variant.openingStock % 1 == 0 ? variant.openingStock.toInt() : variant.openingStock}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                  tooltip: 'Edit Variant',
                                  onPressed: () => _showVariantBottomSheet(
                                    variant: variant,
                                    index: idx,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete Variant',
                                  onPressed: () => setState(
                                    () => _variants.removeAt(idx),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      side: const BorderSide(color: AppTheme.primaryTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _showVariantBottomSheet(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Add Variant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}
}
