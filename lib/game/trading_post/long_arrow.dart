import 'dart:math' as math;
import 'package:flutter/material.dart';

class LongArrow extends StatelessWidget {
  const LongArrow({
    super.key,
    required this.color,
    required this.thickness,
    required this.headSize,
    this.maxWidth,
  });

  final Color color;
  final double thickness;
  final double headSize;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : maxWidth;
        final width = maxWidth != null && availableWidth != null
            ? math.min(availableWidth, maxWidth!)
            : availableWidth ?? maxWidth ?? double.infinity;

        if (width.isInfinite) {
          return CustomPaint(
            painter: _LongArrowPainter(
              color: color,
              thickness: thickness,
              headSize: headSize,
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: width,
            child: CustomPaint(
              painter: _LongArrowPainter(
                color: color,
                thickness: thickness,
                headSize: headSize,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LongArrowPainter extends CustomPainter {
  _LongArrowPainter({
    required this.color,
    required this.thickness,
    required this.headSize,
  });

  final Color color;
  final double thickness;
  final double headSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final y = size.height / 2;
    final start = Offset(0, y);
    final end = Offset(size.width - 2, y);
    canvas.drawLine(start, end, paint);

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final headStart = Offset(size.width - headSize, y - headSize / 2);
    final headMid = Offset(size.width, y);
    final headEnd = Offset(size.width - headSize, y + headSize / 2);

    canvas.drawLine(headStart, headMid, arrowPaint);
    canvas.drawLine(headEnd, headMid, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
