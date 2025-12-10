import 'package:vector_math/vector_math_64.dart';

/// Modelo que representa una ruta de navegación con waypoints
/// Calcula distancia total y tiempo estimado
class NavigationPath {
  /// Lista de puntos intermedios que conforman la ruta
  final List<Vector3> waypoints;

  /// Distancia total de la ruta en metros
  final double totalDistance;

  /// Tiempo estimado en segundos (asumiendo velocidad de caminata ~1.4 m/s)
  final int estimatedTimeSeconds;

  NavigationPath({
    required this.waypoints,
    required this.totalDistance,
    required this.estimatedTimeSeconds,
  });

  /// Velocidad de caminata promedio en metros por segundo
  static const double walkingSpeed = 1.4;

  /// Crea una ruta calculando distancia y tiempo automáticamente
  factory NavigationPath.create(List<Vector3> waypoints) {
    double totalDistance = 0.0;

    // Calcular distancia total sumando distancias entre waypoints consecutivos
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistance += waypoints[i].distanceTo(waypoints[i + 1]);
    }

    // Calcular tiempo estimado basado en velocidad de caminata
    int estimatedTime = (totalDistance / walkingSpeed).ceil();

    return NavigationPath(
      waypoints: waypoints,
      totalDistance: totalDistance,
      estimatedTimeSeconds: estimatedTime,
    );
  }

  /// Obtiene el siguiente waypoint más cercano desde una posición dada
  /// Útil para seguimiento dinámico de la ruta
  Vector3? getNextWaypoint(Vector3 currentPosition, {double threshold = 0.5}) {
    for (var waypoint in waypoints) {
      if (currentPosition.distanceTo(waypoint) > threshold) {
        return waypoint;
      }
    }
    return null; // Ya llegó al final
  }

  /// Calcula el índice del waypoint más cercano a la posición actual
  int getNearestWaypointIndex(Vector3 currentPosition) {
    if (waypoints.isEmpty) return -1;

    int nearestIndex = 0;
    double minDistance = currentPosition.distanceTo(waypoints[0]);

    for (int i = 1; i < waypoints.length; i++) {
      double distance = currentPosition.distanceTo(waypoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// Calcula la distancia restante desde la posición actual
  double getRemainingDistance(Vector3 currentPosition) {
    if (waypoints.isEmpty) return 0.0;

    int nearestIndex = getNearestWaypointIndex(currentPosition);
    double remainingDistance = currentPosition.distanceTo(waypoints[nearestIndex]);

    // Sumar distancias entre los waypoints restantes
    for (int i = nearestIndex; i < waypoints.length - 1; i++) {
      remainingDistance += waypoints[i].distanceTo(waypoints[i + 1]);
    }

    return remainingDistance;
  }

  /// Obtiene tiempo restante estimado desde posición actual
  int getRemainingTime(Vector3 currentPosition) {
    double remainingDistance = getRemainingDistance(currentPosition);
    return (remainingDistance / walkingSpeed).ceil();
  }

  /// Formatea el tiempo en formato legible (min:seg)
  String getFormattedTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  /// Verifica si el usuario ha llegado al destino
  bool hasReachedDestination(Vector3 currentPosition, {double threshold = 1.0}) {
    if (waypoints.isEmpty) return false;
    return currentPosition.distanceTo(waypoints.last) < threshold;
  }

  /// Crea copia con waypoints modificados
  NavigationPath copyWith({
    List<Vector3>? waypoints,
    double? totalDistance,
    int? estimatedTimeSeconds,
  }) {
    return NavigationPath(
      waypoints: waypoints ?? this.waypoints,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedTimeSeconds: estimatedTimeSeconds ?? this.estimatedTimeSeconds,
    );
  }

  @override
  String toString() {
    return 'NavigationPath(waypoints: ${waypoints.length}, distance: ${totalDistance.toStringAsFixed(2)}m, time: ${getFormattedTime(estimatedTimeSeconds)})';
  }
}
