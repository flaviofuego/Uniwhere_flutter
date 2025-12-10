import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/navigation_path.dart';
import '../models/room_location.dart';
import '../utils/constants.dart';

/// Vista esquemática superior de la casa para modo mapa 2D.
class HouseMap extends StatelessWidget {
  const HouseMap({
    super.key,
    required this.locations,
    this.path,
    required this.userPosition,
  });

  final List<RoomLocation> locations;
  final NavigationPath? path;
  final Vector3 userPosition;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _HouseMapPainter(
          locations: locations,
          path: path,
          userPosition: userPosition,
        ),
      ),
    );
  }
}

class _HouseMapPainter extends CustomPainter {
  _HouseMapPainter({
    required this.locations,
    this.path,
    required this.userPosition,
  });

  final List<RoomLocation> locations;
  final NavigationPath? path;
  final Vector3 userPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint border = Paint()
      ..color = darkGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), border);

    // Escalamos las posiciones para que entren en el canvas.
    const double scale = mapScalePixelsPerMeter; // 1 metro = 20px aproximado.
    final Offset origin = Offset(size.width / 2, size.height / 2);

    // Ruta.
    if (path != null) {
      final Paint routePaint = Paint()
        ..color = primaryBlue
        ..strokeWidth = 3;
      for (int i = 0; i < path!.waypoints.length - 1; i++) {
        final Offset a = origin + _toOffset(path!.waypoints[i], scale);
        final Offset b = origin + _toOffset(path!.waypoints[i + 1], scale);
        canvas.drawLine(a, b, routePaint);
      }
    }

    // Ubicaciones.
    final Paint pointPaint = Paint()..color = Colors.blueAccent;
    for (final RoomLocation room in locations) {
      final Offset pos = origin + _toOffset(room.position, scale);
      canvas.drawCircle(pos, 6, pointPaint);
      final TextSpan span = TextSpan(
        text: room.name,
        style: const TextStyle(color: darkGrey, fontSize: 10),
      );
      final TextPainter painter = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, pos + const Offset(8, -4));
    }

    // Usuario.
    final Offset user = origin + _toOffset(userPosition, scale);
    final Paint userPaint = Paint()..color = Colors.green;
    canvas.drawCircle(user, 7, userPaint);
  }

  Offset _toOffset(Vector3 v, double scale) {
    // X -> horizontal, Z -> vertical en el mapa cenital.
    return Offset(v.x * scale, -v.z * scale);
  }

  @override
  bool shouldRepaint(covariant _HouseMapPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.path != path ||
        oldDelegate.userPosition != userPosition;
  }
}
