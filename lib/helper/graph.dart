import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:wallet/model.dart';

class BudgetGraph extends StatelessWidget {
  final double totalBudget;
  final List<Transaction> transactions;
  final DateTime finalDate;
  final ColorScheme colorScheme;

  const BudgetGraph({
    super.key,
    required this.totalBudget,
    required this.transactions,
    required this.finalDate,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final sorted = transactions.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double balance = totalBudget;
    final points = <double>[balance];

    for (final t in sorted) {
      balance += t.isIncome ? t.amount : -t.amount;
      points.add(balance);
    }

    final maxV = points.reduce(math.max);
    final minV = points.reduce(math.min);

    return CustomPaint(
      painter: _GraphPainter(
        points: points,
        max: maxV,
        min: minV,
        color: colorScheme.primary,
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> points;
  final double max;
  final double min;
  final Color color;

  _GraphPainter({
    required this.points,
    required this.max,
    required this.min,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y =
          size.height *
          (1 - ((points[i] - min) / ((max - min).abs() < 1 ? 1 : max - min)));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
