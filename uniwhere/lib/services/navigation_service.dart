import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/room_location.dart';
import '../models/navigation_path.dart';
import '../utils/pathfinding_helper.dart';
import '../utils/constants.dart';

/// Servicio de navegación
/// Calcula rutas, gestiona waypoints y estado de navegación
class NavigationService {
  // Estado de navegación
  RoomLocation? _destination;
  NavigationPath? _currentPath;
  Vector3 _currentPosition = Vector3.zero();
  bool _isNavigating = false;
  bool _justStarted = false; // Evitar detectar llegada inmediata
  
  // Callbacks para notificar cambios
  Function(NavigationPath)? onPathCalculated;
  Function(Vector3)? onPositionUpdated;
  Function()? onDestinationReached;
  Function(double)? onDistanceChanged;

  /// Getters
  RoomLocation? get destination => _destination;
  NavigationPath? get currentPath => _currentPath;
  Vector3 get currentPosition => _currentPosition;
  bool get isNavigating => _isNavigating;

  /// Inicia navegación hacia un destino
  Future<bool> startNavigation(RoomLocation destination, {Vector3? startPosition}) async {
    _destination = destination;
    _currentPosition = startPosition ?? Vector3.zero();
    
    // Calcular ruta
    _currentPath = calculatePath(_currentPosition, destination.position);
    
    if (_currentPath == null) {
      _isNavigating = false;
      return false;
    }
    
    _isNavigating = true;
    _justStarted = true; // Evitar detectar llegada en el primer frame
    
    // Notificar que la ruta fue calculada
    onPathCalculated?.call(_currentPath!);
    
    return true;
  }

  /// Detiene la navegación actual
  void stopNavigation() {
    _isNavigating = false;
    _justStarted = false;
    _destination = null;
    _currentPath = null;
  }

  /// Actualiza la posición actual del usuario
  /// Retorna true si llegó al destino
  bool updatePosition(Vector3 newPosition) {
    _currentPosition = newPosition;
    onPositionUpdated?.call(newPosition);
    
    if (!_isNavigating || _destination == null || _currentPath == null) {
      return false;
    }
    
    // Verificar si llegó al destino
    double distanceToDestination = _currentPosition.distanceTo(_destination!.position);
    onDistanceChanged?.call(distanceToDestination);
    
    // Evitar detectar llegada inmediata al iniciar
    // Solo detectar llegada si ya nos hemos movido un poco o pasaron frames
    if (_justStarted) {
      if (distanceToDestination > AppConstants.destinationThreshold * 2) {
        _justStarted = false; // Ya nos alejamos, ahora sí podemos detectar llegada
      }
      return false; // No detectar llegada todavía
    }
    
    if (distanceToDestination < AppConstants.destinationThreshold) {
      onDestinationReached?.call();
      stopNavigation();
      return true;
    }
    
    return false;
  }

  /// Calcula una ruta entre dos puntos
  NavigationPath? calculatePath(Vector3 start, Vector3 end) {
    // Por ahora usamos ruta directa
    // En futuro se puede implementar con obstáculos usando A*
    List<Vector3> waypoints = PathfindingHelper.calculateDirectPath(
      start,
      end,
      waypointSpacing: 2.0,
    );
    
    return NavigationPath.create(waypoints);
  }

  /// Calcula ruta suave (con curvas)
  NavigationPath? calculateSmoothPath(
    Vector3 start,
    Vector3 end, {
    List<Vector3>? intermediatePoints,
  }) {
    List<Vector3> waypoints = PathfindingHelper.calculateSmoothPath(
      start,
      end,
      intermediatePoints: intermediatePoints,
      smoothness: 10,
    );
    
    return NavigationPath.create(waypoints);
  }

  /// Obtiene el siguiente waypoint en la ruta
  Vector3? getNextWaypoint() {
    if (_currentPath == null) return null;
    return _currentPath!.getNextWaypoint(_currentPosition);
  }

  /// Obtiene la distancia restante al destino
  double getRemainingDistance() {
    if (_currentPath == null) return 0.0;
    return _currentPath!.getRemainingDistance(_currentPosition);
  }

  /// Obtiene el tiempo restante estimado
  int getRemainingTime() {
    if (_currentPath == null) return 0;
    return _currentPath!.getRemainingTime(_currentPosition);
  }

  /// Obtiene tiempo restante formateado
  String getFormattedRemainingTime() {
    if (_currentPath == null) return '0s';
    return _currentPath!.getFormattedTime(getRemainingTime());
  }

  /// Obtiene la dirección hacia el siguiente waypoint
  Vector3? getDirectionToNextWaypoint() {
    final nextWaypoint = getNextWaypoint();
    if (nextWaypoint == null) return null;
    
    return (nextWaypoint - _currentPosition).normalized();
  }

  /// Obtiene la dirección hacia el destino final
  Vector3? getDirectionToDestination() {
    if (_destination == null) return null;
    return (_destination!.position - _currentPosition).normalized();
  }

  /// Calcula el ángulo de rotación hacia el siguiente waypoint
  /// Útil para rotar flechas AR
  double? getAngleToNextWaypoint() {
    final direction = getDirectionToNextWaypoint();
    if (direction == null) return null;
    
    // Calcular ángulo en el plano XZ (horizontal)
    return atan2(direction.x, direction.z);
  }

  /// Recalcula la ruta desde la posición actual
  void recalculateRoute() {
    if (_destination == null) return;
    
    _currentPath = calculatePath(_currentPosition, _destination!.position);
    
    if (_currentPath != null) {
      onPathCalculated?.call(_currentPath!);
    }
  }

  /// Verifica si el usuario se desvió de la ruta
  bool isOffRoute({double threshold = 2.0}) {
    if (_currentPath == null || _currentPath!.waypoints.isEmpty) {
      return false;
    }
    
    // Calcular distancia al camino más cercano
    double minDistance = double.infinity;
    
    for (int i = 0; i < _currentPath!.waypoints.length - 1; i++) {
      double distance = PathfindingHelper.calculateDirectPath(
        _currentPath!.waypoints[i],
        _currentPath!.waypoints[i + 1],
      ).fold<double>(
        double.infinity,
        (min, waypoint) {
          double d = _currentPosition.distanceTo(waypoint);
          return d < min ? d : min;
        },
      );
      
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance > threshold;
  }

  /// Obtiene información de progreso de navegación
  Map<String, dynamic> getNavigationProgress() {
    if (!_isNavigating || _currentPath == null || _destination == null) {
      return {
        'is_navigating': false,
      };
    }
    
    double totalDistance = _currentPath!.totalDistance;
    double remainingDistance = getRemainingDistance();
    double progress = totalDistance > 0 
        ? ((totalDistance - remainingDistance) / totalDistance) * 100 
        : 0.0;
    
    return {
      'is_navigating': true,
      'destination': _destination!.name,
      'total_distance': totalDistance,
      'remaining_distance': remainingDistance,
      'progress_percentage': progress.clamp(0.0, 100.0),
      'estimated_time_remaining': getRemainingTime(),
      'is_off_route': isOffRoute(),
    };
  }

  /// Limpia el estado del servicio
  void dispose() {
    stopNavigation();
    onPathCalculated = null;
    onPositionUpdated = null;
    onDestinationReached = null;
    onDistanceChanged = null;
  }
}

/// Función auxiliar para atan2
double atan2(double y, double x) {
  return math.atan2(y, x);
}
