import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/features/analytics/sales_reports/models/sales_models.dart';
import 'package:flutter/material.dart';

class SalesByCategoryChart extends StatelessWidget {
  final List<CategorySalesData> data;

  const SalesByCategoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No category data'));

    return Column(
      children: data.map((e) => _CategoryRow(category: e)).toList(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySalesData category;

  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.category,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '₹${category.sales.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 6,
                  width: constraints.maxWidth * (category.percentage / 100),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(3),
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
