import 'package:flutter/foundation.dart';
import '../models/point_of_interest.dart';
import '../models/waypoint.dart';
import '../models/navigation_pose.dart';
import '../services/backend_service.dart';

/// Estados posibles de la conexión al backend
enum ConnectionStatus { unknown, connected, disconnected }

/// Estados del proceso de localización visual
enum LocalizationStatus { idle, loading, success, error }

/// Provider central de navegación.
/// Gestiona:
///   - Lista de POIs del campus
///   - Destino seleccionado
///   - Ruta actual (lista de waypoints)
///   - Pose del usuario (resultado de /localize)
///   - Estado de conexión y localización
class NavigationProvider extends ChangeNotifier {
  final BackendService _backendService;

  NavigationProvider({required BackendService backendService})
      : _backendService = backendService;

  // ============================================================================
  // ESTADO DE PUNTOS DE INTERÉS
  // ============================================================================

  List<PointOfInterest> _pois = [];
  bool _loadingPois = false;
  String? _poisError;

  List<PointOfInterest> get pois => _pois;
  bool get loadingPois => _loadingPois;
  String? get poisError => _poisError;

  // ============================================================================
  // ESTADO DE NAVEGACIÓN
  // ============================================================================

  /// Destino seleccionado por el usuario
  PointOfInterest? _selectedDestination;

  /// Ruta actual: lista ordenada de waypoints
  List<Waypoint> _currentRoute = [];

  /// Índice del waypoint actual (hacia dónde se dirige ahora)
  int _currentWaypointIndex = 0;

  /// Última pose conocida del usuario
  NavigationPose? _lastPose;

  /// ¿Está navegando actualmente?
  bool _isNavigating = false;

  PointOfInterest? get selectedDestination => _selectedDestination;
  List<Waypoint> get currentRoute => _currentRoute;
  int get currentWaypointIndex => _currentWaypointIndex;
  NavigationPose? get lastPose => _lastPose;
  bool get isNavigating => _isNavigating;

  /// Waypoint al que se dirige actualmente (null si no hay ruta)
  Waypoint? get nextWaypoint =>
      _currentRoute.isNotEmpty && _currentWaypointIndex < _currentRoute.length
          ? _currentRoute[_currentWaypointIndex]
          : null;

  /// Número de waypoints que quedan incluyendo el actual
  int get remainingWaypoints =>
      _currentRoute.isEmpty ? 0 : _currentRoute.length - _currentWaypointIndex;

  // ============================================================================
  // ESTADO DE CONEXIÓN
  // ============================================================================

  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;
  ConnectionStatus get connectionStatus => _connectionStatus;

  // ============================================================================
  // ESTADO DE LOCALIZACIÓN
  // ============================================================================

  LocalizationStatus _localizationStatus = LocalizationStatus.idle;
  String? _localizationError;

  LocalizationStatus get localizationStatus => _localizationStatus;
  String? get localizationError => _localizationError;
  bool get isLocalizing => _localizationStatus == LocalizationStatus.loading;

  // ============================================================================
  // ACTUALIZAR URL DEL BACKEND
  // ============================================================================

  /// Actualiza la URL del backend cuando cambia desde SettingsScreen
  void updateBackendUrl(String url) {
    _backendService.baseUrl = url;
    // Reiniciar estado de conexión para que se vuelva a comprobar
    _connectionStatus = ConnectionStatus.unknown;
    notifyListeners();
  }

  // ============================================================================
  // COMPROBACIÓN DE CONEXIÓN
  // ============================================================================

  /// Comprueba si el backend responde y actualiza [connectionStatus]
  Future<void> checkConnection() async {
    final ok = await _backendService.checkConnection();
    _connectionStatus = ok ? ConnectionStatus.connected : ConnectionStatus.disconnected;
    notifyListeners();
  }

  // ============================================================================
  // CARGA DE PUNTOS DE INTERÉS
  // ============================================================================

  /// Carga los puntos de interés del campus desde el backend.
  /// Actualiza [pois], [loadingPois] y [poisError].
  Future<void> loadPointsOfInterest() async {
    _loadingPois = true;
    _poisError = null;
    notifyListeners();

    try {
      _pois = await _backendService.getPointsOfInterest();
      _connectionStatus = ConnectionStatus.connected;
    } on BackendException catch (e) {
      _poisError = e.message;
      _connectionStatus = ConnectionStatus.disconnected;
    } catch (e) {
      _poisError = 'Error inesperado al cargar destinos.';
      _connectionStatus = ConnectionStatus.disconnected;
    } finally {
      _loadingPois = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // SELECCIÓN DE DESTINO
  // ============================================================================

  /// Selecciona el destino de navegación sin iniciar aún
  void selectDestination(PointOfInterest poi) {
    _selectedDestination = poi;
    notifyListeners();
  }

  /// Limpia el destino seleccionado
  void clearDestination() {
    _selectedDestination = null;
    notifyListeners();
  }

  // ============================================================================
  // INICIO Y FIN DE NAVEGACIÓN
  // ============================================================================

  /// Inicia la sesión de navegación hacia el destino seleccionado.
  /// Llama a /route si ya tenemos la pose (nearest_node).
  Future<void> startNavigation() async {
    if (_selectedDestination == null) return;
    _isNavigating = true;
    _currentRoute = [];
    _currentWaypointIndex = 0;
    notifyListeners();
  }

  /// Detiene la navegación y limpia el estado
  void stopNavigation() {
    _isNavigating = false;
    _currentRoute = [];
    _currentWaypointIndex = 0;
    _lastPose = null;
    _localizationStatus = LocalizationStatus.idle;
    _localizationError = null;
    notifyListeners();
  }

  // ============================================================================
  // LOCALIZACIÓN VISUAL (POST /localize + GET /route)
  // ============================================================================

  /// Envía un frame al backend para localizar al usuario y actualizar la ruta.
  ///
  /// Flujo:
  ///   1. POST /localize con la imagen → obtenemos pose + nearest_node
  ///   2. GET /route?origin=nearest_node&destination=poi.id → obtenemos waypoints
  ///   3. Actualizar estado y notificar la UI
  Future<void> localizeAndUpdateRoute(Uint8List imageBytes) async {
    if (_selectedDestination == null || !_isNavigating) return;

    _localizationStatus = LocalizationStatus.loading;
    _localizationError = null;
    notifyListeners();

    try {
      // Paso 1: Localizar al usuario
      final pose = await _backendService.localize(imageBytes: imageBytes);
      _lastPose = pose;
      _connectionStatus = ConnectionStatus.connected;

      // Paso 2: Calcular ruta desde el nodo más cercano hasta el destino
      if (pose.nearestNode.isNotEmpty) {
        final route = await _backendService.getRoute(
          origin: pose.nearestNode,
          destination: _selectedDestination!.id,
        );
        _currentRoute = route;
        _currentWaypointIndex = 0;
      }

      _localizationStatus = LocalizationStatus.success;
    } on BackendException catch (e) {
      _localizationStatus = LocalizationStatus.error;
      _localizationError = e.message;
      _connectionStatus = ConnectionStatus.disconnected;
    } catch (e) {
      _localizationStatus = LocalizationStatus.error;
      _localizationError = 'Error inesperado durante la localización.';
    } finally {
      notifyListeners();
    }
  }

  // ============================================================================
  // PROGRESO EN LA RUTA
  // ============================================================================

  /// Avanza al siguiente waypoint de la ruta (cuando el usuario pasa cerca de uno)
  void advanceToNextWaypoint() {
    if (_currentWaypointIndex < _currentRoute.length - 1) {
      _currentWaypointIndex++;
      notifyListeners();
    }
  }

  /// Distancia estimada al destino final (suma de segmentos restantes)
  double get estimatedDistanceToDestination {
    if (_currentRoute.isEmpty) return 0.0;

    double total = 0.0;
    for (int i = _currentWaypointIndex; i < _currentRoute.length - 1; i++) {
      total += _currentRoute[i].distanceTo(_currentRoute[i + 1]);
    }
    return total;
  }
}
