import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../services/navigation_service.dart';
import '../utils/constants.dart';

/// Muestra información de debug solicitada en el enunciado.
class DebugPanel extends StatelessWidget {
  const DebugPanel({
    super.key,
    required this.navigationService,
    required this.detectedPlanes,
    required this.fps,
    required this.trackingState,
  });

  final NavigationService navigationService;
  final int detectedPlanes;
  final int fps;
  final String trackingState;

  @override
  Widget build(BuildContext context) {
    final Vector3 pos = navigationService.userPosition;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('DEBUG AR'),
            Text('Posición: x=${pos.x.toStringAsFixed(2)} '
                'y=${pos.y.toStringAsFixed(2)} '
                'z=${pos.z.toStringAsFixed(2)}'),
            Text('Planos detectados: $detectedPlanes'),
            Text('FPS AR: $fps'),
            Text('Tracking: $trackingState'),
            Text('Distancia al destino: ${navigationService.distanceToDestination.toStringAsFixed(2)} m'),
            if (navigationService.hasArrived)
              const Text(
                'Has llegado',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            if (navigationService.destination != null)
              LinearProgressIndicator(
                value: (navigationService.currentPath?.totalDistance ?? 1) == 0
                    ? 0
                    : (1 -
                        (navigationService.distanceToDestination /
                            (navigationService.currentPath?.totalDistance ?? 1)))
                        .clamp(0, 1),
                color: primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}
