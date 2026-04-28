import 'package:billify/presentation/analytics/widgets/analytics_widgets.dart';
import 'package:billify/features/analytics/profit_reports/models/profit_report_model.dart';
import 'package:flutter/material.dart';

class ProfitSummaryCards extends StatelessWidget {
  final ProfitSummaryModel summary;

  const ProfitSummaryCards({super.key, required this.summary});

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
                  title: 'Total Profit',
                  value: '₹${summary.totalProfit.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  colors: const [Colors.green, Colors.lightGreenAccent],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Revenue',
                  value: '₹${summary.totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  colors: const [Colors.teal, Colors.tealAccent],
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
                  title: 'Cost',
                  value: '₹${summary.totalCost.toStringAsFixed(0)}',
                  icon: Icons.shopping_basket_outlined,
                  colors: const [Colors.orange, Colors.amber],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalyticsCard(
                  title: 'Margin %',
                  value: '${summary.profitMargin.toStringAsFixed(1)}%',
                  icon: Icons.percent,
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
