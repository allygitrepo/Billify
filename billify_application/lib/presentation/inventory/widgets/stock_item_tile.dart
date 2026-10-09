import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StockItemTile extends ConsumerWidget {
  final ProductModel product;
  final String? variantId;
  final double quantity;
  final Function(double) onUpdateQty;
  final VoidCallback? onWeightTap;
  final bool isStockOut;

  const StockItemTile({
    super.key,
    required this.product,
    this.variantId,
    required this.quantity,
    required this.onUpdateQty,
    this.onWeightTap,
    required this.isStockOut,
  });

  String _formatNumber(double val) {
    return val % 1 == 0 ? val.toInt().toString() : val.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uoms = ref.watch(uomProvider);
    final matchedUom = uoms
        .where(
          (u) =>
              u.id == product.uom ||
              (product.base_uom_id != null &&
                  u.id == product.base_uom_id.toString()),
        )
        .firstOrNull;

    final displayUom = matchedUom != null
        ? (matchedUom.shortCode.isNotEmpty
            ? matchedUom.shortCode
            : matchedUom.name)
        : (int.tryParse(product.uom) != null ? '' : product.uom);

    String name = product.name;
    String barcode = product.barcode;
    double currentStock = product.stock;

    if (variantId != null) {
      final variant = product.variants
          .where((v) => v.id == variantId)
          .firstOrNull;
      if (variant != null) {
        name = '${product.name} (${variant.name})';
        barcode = variant.sku;
        currentStock = variant.stock;
      }
    }

    final formattedCurrentStock = _formatNumber(currentStock);
    final formattedQty = _formatNumber(quantity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.photo != null && product.photo!.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            try {
                              return Image.memory(
                                ImageUtils.decodeBase64(product.photo!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 18,
                                    ),
                              );
                            } catch (e) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                                size: 18,
                              );
                            }
                          },
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppTheme.primaryTeal,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Stock: $formattedCurrentStock${displayUom.isNotEmpty ? ' $displayUom' : ''}${barcode.isNotEmpty ? ' | Barcode: $barcode' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () {
                        if (product.is_weighted && onWeightTap != null) {
                          onWeightTap!();
                        } else {
                          onUpdateQty(quantity - 1);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    InkWell(
                      onTap: () {
                        if (product.is_weighted && onWeightTap != null) {
                          onWeightTap!();
                        } else {
                          _showManualQuantityDialog(context, displayUom);
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          formattedQty,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () {
                        if (product.is_weighted && onWeightTap != null) {
                          onWeightTap!();
                        } else {
                          onUpdateQty(quantity + 1);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
            if (isStockOut && currentStock < quantity)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Insufficient stock! Remaining: $formattedCurrentStock${displayUom.isNotEmpty ? ' $displayUom' : ''}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualQuantityDialog(
    BuildContext context,
    String uomLabel,
  ) async {
    final controller = TextEditingController(text: _formatNumber(quantity));
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Quantity for ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter number',
            suffixText: uomLabel.isNotEmpty ? uomLabel : null,
          ),
          onSubmitted: (val) {
            final qty = double.tryParse(val);
            if (qty != null) Navigator.pop(context, qty);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final qty = double.tryParse(controller.text);
              if (qty != null) Navigator.pop(context, qty);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      onUpdateQty(result);
    }
  }
}
