import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/product_model.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumRevenueGraph extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  final String title;

  const PremiumRevenueGraph({
    super.key,
    required this.data,
    required this.labels,
    required this.title,
  });

  @override
  State<PremiumRevenueGraph> createState() => _PremiumRevenueGraphState();
}

class _PremiumRevenueGraphState extends State<PremiumRevenueGraph> {
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 30), // extra padding for labels
          AspectRatio(
            aspectRatio: 1.7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) {
                    if (widget.data.isEmpty) return;
                    final slotWidth = constraints.maxWidth / widget.data.length;
                    int index = (details.localPosition.dx / slotWidth).floor();
                    if (index >= 0 && index < widget.data.length) {
                      setState(() => _tappedIndex = index);
                    }
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _BarChartPainter(widget.data, _tappedIndex),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.labels
                .map(
                  (l) => Expanded(
                    child: Text(
                      l,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final int? tappedIndex;

  _BarChartPainter(this.data, this.tappedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final normalized = data.map((e) => maxVal == 0 ? 0.0 : e / maxVal).toList();

    final slotWidth = size.width / normalized.length;
    final barWidth = slotWidth * 0.6;
    final spacing = slotWidth * 0.4;

    for (var i = 0; i < normalized.length; i++) {
      final isTapped = tappedIndex == i;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: isTapped
              ? [AppTheme.primaryTeal, AppTheme.primaryTeal.withOpacity(0.8)]
              : [AppTheme.primaryTeal.withOpacity(0.4), AppTheme.primaryTeal],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final left = (i * slotWidth) + (spacing / 2);
      final barHeight = normalized[i] * size.height;
      // Prevent completely flat bars if value is tiny but > 0
      final displayHeight = (data[i] > 0 && barHeight < 4) ? 4.0 : barHeight;
      final top = size.height - displayHeight;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, displayHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Always draw the number, but make it bold/larger if tapped
      final valFormatted = data[i] >= 1000
          ? '${(data[i] / 1000).toStringAsFixed(1)}k'
          : data[i].toStringAsFixed(0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: valFormatted,
          style: TextStyle(
            color: isTapped ? AppTheme.primaryTeal : Colors.grey,
            fontSize: isTapped ? 12 : 9,
            fontWeight: isTapped ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          left + (barWidth / 2) - (textPainter.width / 2),
          top - textPainter.height - 4, // draw just above bar
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TopSellingList extends StatelessWidget {
  final Map<String, double> products;
  final List<ProductModel> productModels;

  const TopSellingList({
    super.key,
    required this.products,
    required this.productModels,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final maxSales = products.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Products',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...products.entries.map((e) {
            final percent = maxSales == 0 ? 0.0 : e.value / maxSales;
            return _TopProductRow(
              name: e.key,
              amount: e.value,
              percent: percent,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percent;

  const _TopProductRow({
    required this.name,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.grey),
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
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 8,
                  width: constraints.maxWidth * percent,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryTeal.withOpacity(0.4),
                        AppTheme.primaryTeal,
                      ],
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

class StockAlertSection extends StatelessWidget {
  final List<ProductModel> lowStockProducts;

  const StockAlertSection({super.key, required this.lowStockProducts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stock Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStockProducts.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'All products are well stocked!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            )
          else
            ...lowStockProducts
                .take(3)
                .map((p) => _StockAlertTile(product: p))
                .toList(),
        ],
      ),
    );
  }
}

class _StockAlertTile extends StatelessWidget {
  final ProductModel product;

  const _StockAlertTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (product.uom.isNotEmpty)
                  Text(
                    product.uom,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${product.totalStock} left',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
