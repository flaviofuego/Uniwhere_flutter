import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/waypoint.dart';

class AROverlay extends StatelessWidget {
  final Waypoint destination;
  final double bearing; // Relative bearing to destination
  final double distance; // Distance to destination
  final double devicePitch; // Device tilt angle

  const AROverlay({
    super.key,
    required this.destination,
    required this.bearing,
    required this.distance,
    required this.devicePitch,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Direction arrow
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
          painter: ARArrowPainter(
            bearing: bearing,
            distance: distance,
            devicePitch: devicePitch,
          ),
        ),
        
        // Destination marker
        _buildDestinationMarker(context),
      ],
    );
  }

  Widget _buildDestinationMarker(BuildContext context) {
    // Calculate position on screen based on bearing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Map bearing to horizontal position
    // -180 to 180 degrees maps to left to right of screen
    double normalizedBearing = bearing;
    if (normalizedBearing > 180) {
      normalizedBearing = normalizedBearing - 360;
    }
    
    // Only show marker if destination is within field of view (~60 degrees)
    if (normalizedBearing.abs() > 60) {
      return const SizedBox.shrink();
    }
    
    // Map -60 to 60 degrees to screen width
    final xPosition = screenWidth / 2 + (normalizedBearing / 60) * (screenWidth / 3);
    
    // Adjust vertical position based on pitch and distance
    final yPosition = screenHeight / 2 - (devicePitch * 5) - (20 / (distance + 1));

    return Positioned(
      left: xPosition - 30,
      top: yPosition.clamp(100.0, screenHeight - 200),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  destination.icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  destination.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${distance.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Arrow pointing down to the location
          CustomPaint(
            size: const Size(20, 30),
            painter: DownArrowPainter(),
          ),
        ],
      ),
    );
  }
}

class ARArrowPainter extends CustomPainter {
  final double bearing;
  final double distance;
  final double devicePitch;

  ARArrowPainter({
    required this.bearing,
    required this.distance,
    required this.devicePitch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a navigation arrow at the bottom center pointing to the destination
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final centerX = size.width / 2;
    final centerY = size.height * 0.7;

    // Calculate arrow rotation based on bearing
    double normalizedBearing = bearing;
    if (normalizedBearing > 180) {
      normalizedBearing = normalizedBearing - 360;
    }

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(normalizedBearing * math.pi / 180);

    // Draw arrow
    final path = Path();
    path.moveTo(0, -40); // Top point
    path.lineTo(-25, 20); // Bottom left
    path.lineTo(0, 10); // Center notch
    path.lineTo(25, 20); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    canvas.restore();

    // Draw distance text below arrow
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${distance.toStringAsFixed(1)}m',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY + 40),
    );
  }

  @override
  bool shouldRepaint(ARArrowPainter oldDelegate) {
    return bearing != oldDelegate.bearing ||
        distance != oldDelegate.distance ||
        devicePitch != oldDelegate.devicePitch;
  }
}

class DownArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom point
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
