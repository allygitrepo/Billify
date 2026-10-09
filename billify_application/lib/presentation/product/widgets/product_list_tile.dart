import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/presentation/widgets/status_badge.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductListTile extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListTile({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref
        .watch(authProvider)
        .hasPermission(PermissionModule.products, PermissionAction.update);
    final canDelete = ref
        .watch(authProvider)
        .hasPermission(PermissionModule.products, PermissionAction.delete);

    final isOutOfStock = product.totalStock <= 0;
    final isLowStock = product.totalStock > 0 && product.totalStock < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: canEdit ? onEdit : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            image: ImageUtils.providerFromBase64(
                      product.photo,
                      cacheWidth: 96,
                      cacheHeight: 96,
                    ) !=
                    null
                ? DecorationImage(
                    image: ImageUtils.providerFromBase64(
                      product.photo,
                      cacheWidth: 96,
                      cacheHeight: 96,
                    )!,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.photo == null || product.photo!.isEmpty
              ? const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.primaryTeal,
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (product.hasVariants)
              StatusBadge(
                label: '${product.variants.length} Variants',
                variant: BadgeVariant.info,
                isSmall: true,
              )
            else if (isOutOfStock)
              StatusBadge.outOfStock(label: 'Out of Stock')
            else if (isLowStock)
              StatusBadge.lowStock(label: 'Low (${product.stock})')
            else
              StatusBadge.inStock(label: '₹${product.basePrice.toStringAsFixed(0)}'),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!product.hasVariants)
                Text(
                  '${product.is_weighted ? "Price/Unit" : "Price"}: ₹${product.basePrice.toStringAsFixed(product.basePrice % 1 == 0 ? 0 : 2)} | Stock: ${product.stock % 1 == 0 ? product.stock.toInt() : product.stock}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              if (!product.hasVariants && product.barcode.isNotEmpty)
                Text(
                  'Code: ${product.barcode}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Product',
                onPressed: onEdit,
              ),
            if (canDelete)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
                tooltip: 'Delete Product',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
