import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/navigation_path.dart';
import '../models/room_location.dart';
import '../utils/constants.dart';

/// Servicio central que maneja la posición del usuario, rutas y eventos de navegación.
/// En una versión para campus se integraría con sensores y mapas precisos,
/// aquí usamos cálculos simplificados para mantener la demo ligera.
class NavigationService extends ChangeNotifier {
  NavigationService() {
    _locations = List<RoomLocation>.from(demoLocations);
  }

  /// Lista actual de ubicaciones disponibles.
  late List<RoomLocation> _locations;

  /// Posición simulada del usuario.
  Vector3 _userPosition = Vector3.zero();

  /// Ruta activa.
  NavigationPath? _currentPath;

  /// Destino seleccionado.
  RoomLocation? _destination;

  /// Bitácora simple para el modo debug.
  final List<String> _eventLog = <String>[];

  /// Indica si el sistema está recalibrando mediante VPS.
  bool _recalibrating = false;

  List<RoomLocation> get locations => List<RoomLocation>.unmodifiable(_locations);
  Vector3 get userPosition => _userPosition;
  NavigationPath? get currentPath => _currentPath;
  RoomLocation? get destination => _destination;
  List<String> get eventLog => List<String>.unmodifiable(_eventLog);
  bool get recalibrating => _recalibrating;

  /// Calcula la distancia en metros al destino actual.
  double get distanceToDestination {
    if (_destination == null) return 0;
    return (_destination!.position - _userPosition).length;
  }

  /// Color de la flecha según cercanía.
  Color get arrowColor {
    final double distance = distanceToDestination;
    if (distance < 1) return Colors.green;
    if (distance < 3) return Colors.yellow.shade700;
    return Colors.red;
  }

  /// Actualiza la posición del usuario (simulada) y recalcula estado.
  void updateUserPosition(Vector3 newPosition) {
    _userPosition = newPosition;
    _log('Posición actualizada a (${newPosition.x.toStringAsFixed(2)}, '
        '${newPosition.y.toStringAsFixed(2)}, ${newPosition.z.toStringAsFixed(2)})');
    _refreshPath();
    notifyListeners();
  }

  /// Inicia una navegación simple en línea recta hacia el destino indicado.
  void startNavigation(RoomLocation target) {
    _destination = target;
    _recalibrating = false;
    _currentPath = _buildPath(_userPosition, target.position);
    _log('Navegación iniciada hacia ${target.name}');
    notifyListeners();
  }

  /// Limpia el estado de navegación.
  void stopNavigation() {
    _log('Navegación detenida');
    _destination = null;
    _currentPath = null;
    notifyListeners();
  }

  /// Agrega una nueva ubicación si no superamos el límite definido.
  void addLocation(RoomLocation location) {
    if (_locations.length >= maxLocations) {
      _log('Límite de ubicaciones alcanzado');
      return;
    }
    _locations = List<RoomLocation>.from(_locations)..add(location);
    _log('Ubicación ${location.name} guardada en la demo');
    notifyListeners();
  }

  /// Simula un match de VPS moviendo la posición al punto de referencia.
  void applyVpsMatch(RoomLocation location) {
    _recalibrating = true;
    notifyListeners();
    // En una app real se haría tras recibir resultado de ML Kit.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      _userPosition = location.position;
      _recalibrating = false;
      _log('Posición recalibrada con referencia ${location.imageReference ?? location.id}');
      _refreshPath();
      notifyListeners();
    });
  }

  /// Devuelve true cuando estamos a menos de un metro.
  bool get hasArrived => distanceToDestination <= 1 && _destination != null;

  /// Recalcula la ruta si existe un destino activo.
  void _refreshPath() {
    if (_destination == null) return;
    _currentPath = _buildPath(_userPosition, _destination!.position);
  }

  /// Construcción de ruta básica: dos puntos y distancia recta.
  NavigationPath _buildPath(Vector3 start, Vector3 end) {
    // TODO(campus): reemplazar por A* sobre plano importado del campus cuando se tenga el mapa real.
    final double distance = (end - start).length;
    final int estimatedTime = max(1, (distance / walkingSpeedMps).round());
    return NavigationPath(
      waypoints: <Vector3>[start, end],
      totalDistance: distance,
      estimatedTimeSeconds: estimatedTime,
    );
  }

  void _log(String message) {
    _eventLog.insert(0, '${DateTime.now().toIso8601String()} - $message');
    if (_eventLog.length > 50) {
      _eventLog.removeLast();
    }
  }
}
