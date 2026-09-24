import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:billify/data/models/uom_model.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/uom_provider.dart';
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
            image: product.photo != null && product.photo!.isNotEmpty
                ? DecorationImage(
                    image: MemoryImage(ImageUtils.decodeBase64(product.photo!)),
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
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
            if (canDelete)
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
