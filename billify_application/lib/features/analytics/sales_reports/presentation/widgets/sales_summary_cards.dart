import 'package:billify_application/presentation/analytics/widgets/analytics_widgets.dart';
import 'package:billify_application/features/analytics/sales_reports/models/sales_models.dart';
import 'package:flutter/material.dart';

class SalesSummaryCards extends StatelessWidget {
  final SalesSummaryModel summary;

  const SalesSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2.2,
          child: Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Total Sales',
                  value: '₹${summary.totalSales.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  colors: const [Colors.teal, Colors.tealAccent],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Average Bill',
                  value: '₹${summary.avgBillValue.toStringAsFixed(0)}',
                  icon: Icons.receipt,
                  colors: const [Colors.blue, Colors.lightBlueAccent],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 2.2,
          child: Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Total Orders',
                  value: summary.totalOrders.toString(),
                  icon: Icons.shopping_basket_outlined,
                  colors: const [Colors.orange, Colors.amber],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Items Sold',
                  value: summary.totalItemsSold.toString(),
                  icon: Icons.inventory_2_outlined,
                  colors: const [Colors.purple, Colors.deepPurpleAccent],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
