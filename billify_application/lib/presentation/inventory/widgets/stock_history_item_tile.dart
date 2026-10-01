import 'package:billify/core/enums/stock_mode.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/stock_history_model.dart';
import 'package:billify/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StockHistoryItemTile extends ConsumerWidget {
  final StockHistoryModel history;

  const StockHistoryItemTile({super.key, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('hh:mm a');
    final isStockIn = history.change_type == StockMode.inMode;
    final isInvoice = history.source.toLowerCase() == 'invoice' ||
        history.reason.toLowerCase().contains('sale') ||
        history.reason.toLowerCase().contains('inv');

    // Find product to get image/name
    final product = ref
        .watch(productsListProvider)
        .where((p) => p.id.toString() == history.product_id)
        .firstOrNull;

    final String displayName = history.variant_name.isNotEmpty &&
            history.variant_name != 'No Variant' &&
            history.variant_name != 'Default'
        ? history.variant_name
        : (product?.name.isNotEmpty == true ? product!.name : 'Product');

    final qtyNumber = history.quantity_change;
    final qtyFormatted = qtyNumber % 1 == 0
        ? qtyNumber.toInt().toString()
        : qtyNumber.toStringAsFixed(2);
    final sign = isStockIn ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isInvoice
                        ? Colors.blue
                        : (isStockIn ? Colors.green : Colors.orange))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: product?.photo != null && product!.photo!.isNotEmpty
                  ? Image(
                      image: ImageUtils.providerFromBase64(product.photo)!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                      ),
                    )
                  : Icon(
                      isInvoice
                          ? Icons.receipt_long_outlined
                          : (isStockIn
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline),
                      color: isInvoice
                          ? Colors.blue
                          : (isStockIn ? Colors.green : Colors.orange),
                      size: 20,
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isInvoice
                      ? Colors.blue
                      : (isStockIn ? Colors.green : Colors.orange),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  isInvoice
                      ? Icons.receipt
                      : (isStockIn ? Icons.add : Icons.remove),
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isInvoice ? Colors.blue : Colors.grey)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isInvoice ? 'SALE' : 'MANUAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isInvoice ? Colors.blue : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: ${history.reason}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isInvoice ? Colors.blue.shade700 : AppTheme.primaryTeal,
              ),
            ),
            Text(
              timeFormat.format(history.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isStockIn ? Colors.green : Colors.orange)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$sign$qtyFormatted',
            style: TextStyle(
              color: isStockIn ? Colors.green.shade700 : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
