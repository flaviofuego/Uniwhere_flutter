import 'package:vector_math/vector_math_64.dart';

/// Modelo de ruta que guarda los puntos de paso y tiempos estimados.
class NavigationPath {
  /// Lista de puntos que conforman la ruta desde la posición actual al destino.
  final List<Vector3> waypoints;

  /// Distancia total en metros.
  final double totalDistance;

  /// Tiempo estimado en segundos (cálculo simplificado).
  final int estimatedTimeSeconds;

  const NavigationPath({
    required this.waypoints,
    required this.totalDistance,
    required this.estimatedTimeSeconds,
  });
}
