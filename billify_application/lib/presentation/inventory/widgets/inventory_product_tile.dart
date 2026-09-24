import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/product_variant_model.dart';
import 'package:billify/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryProductTile extends ConsumerWidget {
  final ProductModel product;

  const InventoryProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uoms = ref.watch(uomProvider);
    final resolvedUom =
        uoms.where((u) => u.id == product.uom).firstOrNull?.shortCode ??
        product.uom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        key: PageStorageKey('inventory_${product.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
                              size: 20,
                            ),
                      );
                    } catch (e) {
                      return const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                      );
                    }
                  },
                )
              : const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primaryTeal,
                  size: 24,
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: product.hasVariants
            ? Text(
                '${product.variants.length} Variants',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              )
            : Text(
                'Price: ₹${product.basePrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
        trailing: !product.hasVariants
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (product.stock <= 0
                              ? Colors.red
                              : (product.stock > 10
                                    ? Colors.green
                                    : Colors.orange))
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.stock <= 0
                      ? 'OUT OF STOCK'
                      : '${product.stock} $resolvedUom',
                  style: TextStyle(
                    color: product.stock <= 0
                        ? Colors.red
                        : (product.stock > 10 ? Colors.green : Colors.orange),
                    fontWeight: FontWeight.bold,
                    fontSize: product.stock <= 0 ? 10 : 12,
                  ),
                ),
              )
            : null,
        children: product.hasVariants
            ? product.variants
                  .map(
                    (v) => _InventoryVariantTile(variant: v, uom: resolvedUom),
                  )
                  .toList()
            : [],
      ),
    );
  }
}

class _InventoryVariantTile extends StatelessWidget {
  final ProductVariantModel variant;
  final String uom;

  const _InventoryVariantTile({required this.variant, required this.uom});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.subdirectory_arrow_right,
              size: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Price: ₹${variant.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (variant.stock <= 0
                          ? Colors.red
                          : (variant.stock > 5 ? Colors.green : Colors.orange))
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              variant.stock <= 0
                  ? 'OUT OF STOCK'
                  : '${variant.stock} ${uom.isNotEmpty ? uom : ''}',
              style: TextStyle(
                color: variant.stock <= 0
                    ? Colors.red
                    : (variant.stock > 5 ? Colors.green : Colors.orange),
                fontWeight: FontWeight.bold,
                fontSize: variant.stock <= 0 ? 10 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
