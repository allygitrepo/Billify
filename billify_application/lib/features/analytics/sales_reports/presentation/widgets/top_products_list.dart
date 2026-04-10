import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/features/analytics/sales_reports/models/sales_models.dart';
import 'package:flutter/material.dart';

class TopProductsList extends StatelessWidget {
  final List<TopProductData> products;

  const TopProductsList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const Center(child: Text('No products data'));

    return Column(
      children: products.map((p) => _ProductRow(product: p)).toList(),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final TopProductData product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '₹${product.revenue.toStringAsFixed(0)} (${product.quantity})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 8,
                  width: constraints.maxWidth * (product.percentage / 100),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryTeal, Colors.teal],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
