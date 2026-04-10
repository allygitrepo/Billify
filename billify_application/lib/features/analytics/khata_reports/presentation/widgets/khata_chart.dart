import 'package:billify_application/features/analytics/khata_reports/models/khata_report_model.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class KhataDueTrendsChart extends StatelessWidget {
  final List<KhataChartPoint> points;

  const KhataDueTrendsChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No trend data available'));

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _KhataLineChartPainter(points, Theme.of(context).brightness == Brightness.dark),
    );
  }
}

class _KhataLineChartPainter extends CustomPainter {
  final List<KhataChartPoint> data;
  final bool isDarkMode;

  _KhataLineChartPainter(this.data, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.map((e) => e.value).reduce(math.max);
    final normalized = data.map((e) => maxVal == 0 ? 0.0 : e.value / maxVal).toList();
    
    final xStep = size.width / (normalized.length > 1 ? normalized.length - 1 : 1);
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < normalized.length; i++) {
       final x = i * xStep;
       final y = size.height - (normalized[i] * size.height * 0.8);
       if (i == 0) {
         path.moveTo(x, y);
       } else {
         path.lineTo(x, y);
       }
    }
    
    canvas.drawPath(path, paint);
    
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.redAccent.withOpacity(0.2),
          Colors.redAccent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class KhataTopDueChart extends StatelessWidget {
  final List<KhataDueReportItem> customers;

  const KhataTopDueChart({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) return const Center(child: Text('No top due data'));

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _KhataBarChartPainter(customers, Theme.of(context).brightness == Brightness.dark),
    );
  }
}

class _KhataBarChartPainter extends CustomPainter {
  final List<KhataDueReportItem> customers;
  final bool isDarkMode;

  _KhataBarChartPainter(this.customers, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    if (customers.isEmpty) return;

    final maxVal = customers.map((e) => e.totalDue).reduce(math.max);
    final barWidth = size.width / (customers.length * 2);
    final spacing = size.width / customers.length;

    for (var i = 0; i < customers.length; i++) {
      final h = (customers[i].totalDue / maxVal) * size.height * 0.8;
      final x = (i * spacing) + (spacing - barWidth) / 2;
      final y = size.height - h;

      final paint = Paint()
        ..color = Colors.redAccent.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class KhataPaidDuePieChart extends StatelessWidget {
  final double paid;
  final double due;

  const KhataPaidDuePieChart({super.key, required this.paid, required this.due});

  @override
  Widget build(BuildContext context) {
    final total = paid + due;
    final percentage = total == 0 ? 0.0 : (paid / total);

    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 15,
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(percentage * 100).toStringAsFixed(0)}%', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Paid', style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
