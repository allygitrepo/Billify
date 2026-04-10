import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/features/analytics/sales_reports/models/sales_models.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SalesTrendChart extends StatelessWidget {
  final List<SalesChartData> data;

  const SalesTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data for this period'));

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _SalesLineChartPainter(data, Theme.of(context).brightness == Brightness.dark),
    );
  }
}

class _SalesLineChartPainter extends CustomPainter {
  final List<SalesChartData> data;
  final bool isDarkMode;

  _SalesLineChartPainter(this.data, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.map((e) => e.amount).reduce(math.max);
    final normalized = data.map((e) => maxVal == 0 ? 0.0 : e.amount / maxVal).toList();
    
    final xStep = size.width / (normalized.length > 1 ? normalized.length - 1 : 1);
    final paint = Paint()
      ..color = AppTheme.primaryTeal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < normalized.length; i++) {
       final x = i * xStep;
       final y = size.height - (normalized[i] * size.height * 0.8); // 0.8 to leave top padding
       if (i == 0) {
         path.moveTo(x, y);
       } else {
         path.lineTo(x, y);
       }
    }
    
    canvas.drawPath(path, paint);
    
    // Gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryTeal.withOpacity(0.3),
          AppTheme.primaryTeal.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);

    // Draw dots at points
    final dotPaint = Paint()
      ..color = AppTheme.primaryTeal
      ..style = PaintingStyle.fill;
      
    for (var i = 0; i < normalized.length; i++) {
        final x = i * xStep;
        final y = size.height - (normalized[i] * size.height * 0.8);
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
        
        if (isDarkMode) {
          canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
        }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
