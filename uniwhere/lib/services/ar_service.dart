import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';

/// Servicio AR con ar_flutter_plugin_plus
/// Gestiona sesión AR, tracking y posicionamiento
class ARService {
  // Managers de ar_flutter_plugin
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  ARLocationManager? _arLocationManager;

  // Estado del tracking
  bool _isTracking = false;
  bool _planesDetected = false;
  Vector3 _currentPosition = Vector3.zero();
  Vector3 _currentRotation = Vector3.zero();
  int _detectedPlanesCount = 0;
  
  // Origen del sistema de coordenadas AR
  Vector3 _origin = Vector3.zero();
  bool _originSet = false;
  
  // Callbacks
  Function(bool)? onTrackingStateChanged;
  Function(Vector3)? onPositionUpdated;
  Function(Vector3)? onRotationUpdated;
  Function(int)? onPlanesDetectedCountChanged;
  
  // Simulación de movimiento (para testing)
  Timer? _simulationTimer;
  bool _isSimulating = false;

  /// Getters
  bool get isTracking => _isTracking;
  bool get planesDetected => _planesDetected;
  Vector3 get currentPosition => _currentPosition;
  Vector3 get currentRotation => _currentRotation;
  int get detectedPlanesCount => _detectedPlanesCount;
  bool get originSet => _originSet;
  Vector3 get origin => _origin;

  /// Inicializa la sesión AR
  Future<bool> initialize() async {
    try {
      // ar_flutter_plugin maneja la disponibilidad internamente
      debugPrint('✅ AR Service inicializado');
      return true;
    } catch (e) {
      debugPrint('❌ Error al inicializar AR Service: $e');
      return false;
    }
  }
  
  /// Callback cuando la vista AR es creada
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _arSessionManager = sessionManager;
    _arObjectManager = objectManager;
    _arAnchorManager = anchorManager;
    _arLocationManager = locationManager;

    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: true,
      handleTaps: false,
    );
    _arObjectManager!.onInitialize();

    _isTracking = true;
    onTrackingStateChanged?.call(true);
    
    // Simulamos detección de planos ya que el plugin los maneja visualmente
    _planesDetected = true;
    _detectedPlanesCount = 1;
    onPlanesDetectedCountChanged?.call(_detectedPlanesCount);
    
    debugPrint('✅ ARView configurado');
  }

  /// Obtiene el widget de vista AR
  /// Mantenemos el nombre getARCoreView para compatibilidad, aunque usa ar_flutter_plugin
  Widget getARCoreView({
    required Function(dynamic) onViewCreated,
    bool enableTapRecognizer = false,
  }) {
    return ARView(
      onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) {
        onARViewCreated(sessionManager, objectManager, anchorManager, locationManager);
        // Llamamos al callback original pasando el sessionManager como "controller"
        onViewCreated(sessionManager);
      },
      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
    );
  }

  /// Inicia el tracking AR
  Future<bool> startTracking() async {
    if (_isTracking) return true;
    
    try {
      // El tracking inicia con la vista
      await Future.delayed(const Duration(milliseconds: 300));
      
      _isTracking = true;
      _planesDetected = false;
      _detectedPlanesCount = 0;
      
      onTrackingStateChanged?.call(true);
      
      // Simular detección de planos después de un momento
      Future.delayed(const Duration(seconds: 2), () {
        _planesDetected = true;
        _detectedPlanesCount = 3; // Simulamos 3 planos detectados
        onPlanesDetectedCountChanged?.call(_detectedPlanesCount);
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Detiene el tracking AR
  void stopTracking() {
    _isTracking = false;
    _planesDetected = false;
    _detectedPlanesCount = 0;
    onTrackingStateChanged?.call(false);
    // Podríamos limpiar sesión aquí si fuera necesario
    // _arSessionManager?.dispose(); 
  }

  /// Establece el origen del sistema de coordenadas
  /// Este será el punto (0,0,0) de referencia
  void setOrigin(Vector3 position) {
    _origin = position;
    _originSet = true;
    _currentPosition = Vector3.zero(); // Resetear a origen local
  }

  /// Resetea el origen
  void resetOrigin() {
    _origin = Vector3.zero();
    _originSet = false;
    _currentPosition = Vector3.zero();
  }

  /// Actualiza la posición del dispositivo en el espacio AR
  /// Posición en coordenadas relativas al origen
  void updatePosition(Vector3 newPosition) {
    if (_originSet) {
      // Convertir a coordenadas locales relativas al origen
      _currentPosition = newPosition - _origin;
    } else {
      _currentPosition = newPosition;
    }
    
    onPositionUpdated?.call(_currentPosition);
  }

  /// Actualiza la rotación del dispositivo
  /// Rotación en ángulos de Euler (x, y, z)
  void updateRotation(Vector3 newRotation) {
    _currentRotation = newRotation;
    onRotationUpdated?.call(_currentRotation);
  }

  /// Obtiene la posición en coordenadas del mundo
  Vector3 getWorldPosition() {
    if (_originSet) {
      return _origin + _currentPosition;
    }
    return _currentPosition;
  }

  /// Convierte de coordenadas de mundo a coordenadas locales
  Vector3 worldToLocal(Vector3 worldPosition) {
    if (_originSet) {
      return worldPosition - _origin;
    }
    return worldPosition;
  }

  /// Convierte de coordenadas locales a coordenadas de mundo
  Vector3 localToWorld(Vector3 localPosition) {
    if (_originSet) {
      return _origin + localPosition;
    }
    return localPosition;
  }

  /// Verifica si un punto está dentro del rango de renderizado
  bool isInRenderRange(Vector3 point, {double maxDistance = 50.0}) {
    return _currentPosition.distanceTo(point) <= maxDistance;
  }

  /// Calcula la dirección de la cámara (hacia donde apunta el dispositivo)
  Vector3 getCameraDirection() {
    // Usar rotación Y (yaw) para determinar dirección horizontal
    double yaw = _currentRotation.y;
    return Vector3(
      sin(yaw),
      0, // Ignoramos pitch por ahora
      -cos(yaw),
    ).normalized();
  }

  /// Verifica si el usuario está apuntando hacia un objetivo
  bool isPointingAt(Vector3 target, {double angleTolerance = 0.3}) {
    Vector3 cameraDir = getCameraDirection();
    Vector3 toTarget = (target - _currentPosition).normalized();
    
    double angle = acos(cameraDir.dot(toTarget).clamp(-1.0, 1.0));
    return angle < angleTolerance;
  }

  // ==========================================================================
  // MODO SIMULACIÓN (para testing sin hardware AR)
  // ==========================================================================

  /// Inicia simulación de movimiento para testing
  void startSimulation({
    Vector3? startPosition,
    double speed = 0.5, // metros por segundo
  }) {
    if (_isSimulating) return;
    
    _isSimulating = true;
    _currentPosition = startPosition ?? Vector3.zero();
    
    // Timer que actualiza posición cada 100ms
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        // Simular movimiento aleatorio
        _currentPosition += Vector3(
          (0.5 - (timer.tick % 10) / 10.0) * speed * 0.1,
          0,
          (0.5 - (timer.tick % 7) / 7.0) * speed * 0.1,
        );
        
        onPositionUpdated?.call(_currentPosition);
      },
    );
  }

  /// Detiene la simulación
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isSimulating = false;
  }

  /// Simula movimiento hacia un objetivo
  void simulateMovementTowards(Vector3 target, {double speed = 0.5}) {
    if (_simulationTimer != null) {
      _simulationTimer!.cancel();
    }
    
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        Vector3 direction = (target - _currentPosition).normalized();
        double distance = _currentPosition.distanceTo(target);
        
        if (distance < 0.1) {
          // Llegamos al objetivo
          stopSimulation();
          return;
        }
        
        _currentPosition += direction * speed * 0.1;
        onPositionUpdated?.call(_currentPosition);
      },
    );
  }

  // ==========================================================================
  // INFORMACIÓN DE DEBUG
  // ==========================================================================

  /// Obtiene información de estado para debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'is_tracking': _isTracking,
      'planes_detected': _planesDetected,
      'planes_count': _detectedPlanesCount,
      'current_position': '(${_currentPosition.x.toStringAsFixed(2)}, ${_currentPosition.y.toStringAsFixed(2)}, ${_currentPosition.z.toStringAsFixed(2)})',
      'current_rotation': '(${_currentRotation.x.toStringAsFixed(2)}, ${_currentRotation.y.toStringAsFixed(2)}, ${_currentRotation.z.toStringAsFixed(2)})',
      'origin_set': _originSet,
      'is_simulating': _isSimulating,
    };
  }

  /// Limpia recursos
  void dispose() {
    stopTracking();
    stopSimulation();
    _arSessionManager?.dispose();
    onTrackingStateChanged = null;
    onPositionUpdated = null;
    onRotationUpdated = null;
    onPlanesDetectedCountChanged = null;
  }
}

// Funciones auxiliares para cálculos trigonométricos
double sin(double radians) => math.sin(radians);
double cos(double radians) => math.cos(radians);
double acos(double value) => math.acos(value);
