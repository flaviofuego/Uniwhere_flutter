import 'package:flutter/material.dart';

import '../models/navigation_path.dart';

/// Dibuja una representación simplificada de la ruta en la vista AR.
/// Solo es una guía visual para la demo; en producción se reemplaza por geometría 3D.
class ArRouteOverlay extends StatelessWidget {
  const ArRouteOverlay({
    super.key,
    required this.path,
    required this.arrowColor,
    required this.recalibrating,
  });

  final NavigationPath? path;
  final Color arrowColor;
  final bool recalibrating;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ArRoutePainter(
          arrowColor: arrowColor,
          recalibrating: recalibrating,
        ),
        child: Container(),
      ),
    );
  }
}

class _ArRoutePainter extends CustomPainter {
  _ArRoutePainter({
    required this.arrowColor,
    required this.recalibrating,
  });

  final Color arrowColor;
  final bool recalibrating;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = arrowColor.withOpacity(0.7)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final Offset start = Offset(size.width * 0.2, size.height * 0.85);
    final Offset end = Offset(size.width * 0.8, size.height * 0.2);
    canvas.drawLine(start, end, linePaint);

    final Path arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 12, end.dy + 16)
      ..lineTo(end.dx + 12, end.dy + 16)
      ..close();

    final Paint arrowPaint = Paint()
      ..color = recalibrating ? Colors.orange : arrowColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrow, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _ArRoutePainter oldDelegate) {
    return oldDelegate.arrowColor != arrowColor ||
        oldDelegate.recalibrating != recalibrating;
  }
}
