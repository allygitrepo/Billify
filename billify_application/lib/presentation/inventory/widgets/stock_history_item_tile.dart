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
    final isInvoice = history.source == 'invoice';

    // Find product to get image
    final product = ref
        .watch(productsListProvider)
        .where((p) => p.id == history.product_id)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
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
                        ? AppTheme.primaryTeal
                        : (isStockIn ? Colors.green : Colors.orange))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: product?.photo != null && product!.photo!.isNotEmpty
                  ? Image.memory(
                      ImageUtils.decodeBase64(product.photo!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
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
                          ? AppTheme.primaryTeal
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
                      ? AppTheme.primaryTeal
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
                history.variant_name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isInvoice ? Colors.blue : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                history.source.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isInvoice ? Colors.blue : Colors.grey,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTeal,
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
            color: (isStockIn ? Colors.green : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${isStockIn ? '+' : ''}${history.quantity_change}',
            style: TextStyle(
              color: isStockIn ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
