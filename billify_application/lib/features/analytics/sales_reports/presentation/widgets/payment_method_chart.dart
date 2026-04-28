import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/features/analytics/sales_reports/models/sales_models.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PaymentMethodChart extends StatelessWidget {
  final List<PaymentMethodData> data;

  const PaymentMethodChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No payment data'));

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: _PieChartPainter(data)),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data
                .map(
                  (e) => _LegendItem(
                    label: e.method,
                    percent: e.percentage.toStringAsFixed(1),
                    color: _getColor(data.indexOf(e)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Color _getColor(int i) {
    final colors = [
      AppTheme.primaryTeal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.green,
    ];
    return colors[i % colors.length];
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PaymentMethodData> data;

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    var startAngle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = _getColor(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 15),
        startAngle + 0.05, // small gap between segments
        sweepAngle - 0.1,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Centered percentage for the largest method
    if (data.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${data[0].percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primaryTeal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Color _getColor(int i) {
    final colors = [
      AppTheme.primaryTeal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.green,
    ];
    return colors[i % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '$percent%',
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
