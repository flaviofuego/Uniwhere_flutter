import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Panel de debug que muestra información técnica del sistema AR
/// Útil para desarrollo y diagnóstico
class DebugPanel extends StatelessWidget {
  final Map<String, dynamic> debugInfo;
  final bool visible;

  const DebugPanel({
    super.key,
    required this.debugInfo,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      top: 50,
      left: AppConstants.defaultSpacing,
      right: AppConstants.defaultSpacing,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'DEBUG INFO',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            
            // Información de debug
            ...debugInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// Widget simple para mostrar FPS
class FPSCounter extends StatelessWidget {
  final double fps;

  const FPSCounter({
    super.key,
    required this.fps,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (fps >= 25) {
      color = AppConstants.successColor;
    } else if (fps >= 15) {
      color = AppConstants.warningColor;
    } else {
      color = AppConstants.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '${fps.toStringAsFixed(0)} FPS',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar coordenadas actuales
class CoordinatesDisplay extends StatelessWidget {
  final double x;
  final double y;
  final double z;

  const CoordinatesDisplay({
    super.key,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoordText('X: ${x.toStringAsFixed(2)}m'),
          _CoordText('Y: ${y.toStringAsFixed(2)}m'),
          _CoordText('Z: ${z.toStringAsFixed(2)}m'),
        ],
      ),
    );
  }
}

class _CoordText extends StatelessWidget {
  final String text;

  const _CoordText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
  }
}
