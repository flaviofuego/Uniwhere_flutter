import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:camera/camera.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import '../models/room_location.dart';
import '../services/ar_service.dart';
import '../services/navigation_service.dart';
import '../services/storage_service.dart';
import '../services/permissions_service.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/ar_navigation_arrow.dart';
import '../widgets/debug_panel.dart';
import '../utils/constants.dart';
import 'dart:async';

/// Pantalla de navegación AR
/// Muestra vista de cámara simulada con overlay de navegación
class NavigationScreen extends StatefulWidget {
  final RoomLocation? destination;

  const NavigationScreen({super.key, this.destination});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late ARService _arService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late PermissionsService _permissionsService;
  
  bool _isInitialized = false;
  bool _isNavigating = false;
  bool _debugMode = false;
  bool _useModel3D = true; // Intentar usar modelo 3D primero
  Timer? _updateTimer;
  
  // Sesión AR (usado para control avanzado de la sesión)
  // ignore: unused_field
  ARSessionManager? _arSessionManager;
  
  // Cámara
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  // Ubicaciones disponibles
  List<RoomLocation> _locations = [];
  RoomLocation? _selectedDestination;
  
  // Estado de navegación
  double _currentDistance = 0;
  int _currentTime = 0;
  bool _isOffRoute = false;
  
  // Tracking de posición más preciso
  Vector3 _lastKnownPosition = Vector3.zero();
  List<Vector3> _positionHistory = [];
  static const int _maxPositionHistory = 10;

  @override
  void initState() {
    super.initState();
    _arService = context.read<ARService>();
    _navigationService = context.read<NavigationService>();
    _storageService = context.read<StorageService>();
    _permissionsService = context.read<PermissionsService>();
    
    _selectedDestination = widget.destination;
    _initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Usar cámara trasera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Error al inicializar cámara: $e');
      // Continuar sin cámara - mostrará fondo gradiente
    }
  }

  Future<void> _initialize() async {
    try {
      // Solicitar permisos primero
      await _permissionsService.requestCameraPermission();

      // Inicializar AR primero
      bool arInitialized = await _arService.initialize();
      if (!arInitialized) {
        // Si ARCore no está disponible, usar simulación con cámara
        debugPrint('⚠️ ARCore no disponible, usando modo simulación con cámara');
        await _initializeCamera();
      }
      
      await _arService.startTracking();
      
      // Cargar ubicaciones
      _locations = _storageService.getAllLocations();
      
      // Cargar modo debug
      _debugMode = _storageService.getDebugMode();
      
      // Establecer origen si no está configurado
      if (!_arService.originSet) {
        _arService.setOrigin(Vector3.zero());
      }
      
      // Iniciar simulación de movimiento para testing (solo si no hay ARCore)
      if (!arInitialized) {
        _arService.startSimulation(startPosition: Vector3.zero());
      }
      
      // Si hay destino preseleccionado, iniciar navegación
      if (_selectedDestination != null) {
        _startNavigation(_selectedDestination!);
      }
      
      // Timer para actualizar estado
      _updateTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) => _updateNavigationState(),
      );
      
      setState(() => _isInitialized = true);
      
      // Configurar callbacks de navegación
      _navigationService.onDestinationReached = _onDestinationReached;
      _navigationService.onDistanceChanged = (distance) {
        setState(() => _currentDistance = distance);
      };
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar AR: $e')),
        );
      }
    }
  }

  void _updateNavigationState() {
    if (!_isNavigating || !mounted) return;
    
    // Obtener posición actual del AR
    Vector3 currentPos = _arService.currentPosition;
    
    // Suavizar posición para mayor precisión (promedio móvil)
    _positionHistory.add(currentPos);
    if (_positionHistory.length > _maxPositionHistory) {
      _positionHistory.removeAt(0);
    }
    
    // Calcular posición suavizada
    Vector3 smoothedPosition = _calculateSmoothedPosition();
    _lastKnownPosition = smoothedPosition;
    
    // Actualizar posición en el servicio de navegación
    _navigationService.updatePosition(smoothedPosition);
    
    // Actualizar estado
    setState(() {
      _currentDistance = _navigationService.getRemainingDistance();
      _currentTime = _navigationService.getRemainingTime();
      _isOffRoute = _navigationService.isOffRoute();
    });
  }
  
  /// Calcula una posición suavizada usando promedio móvil
  Vector3 _calculateSmoothedPosition() {
    if (_positionHistory.isEmpty) return Vector3.zero();
    if (_positionHistory.length == 1) return _positionHistory.first;
    
    double sumX = 0, sumY = 0, sumZ = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < _positionHistory.length; i++) {
      // Mayor peso a posiciones más recientes
      double weight = (i + 1).toDouble();
      sumX += _positionHistory[i].x * weight;
      sumY += _positionHistory[i].y * weight;
      sumZ += _positionHistory[i].z * weight;
      totalWeight += weight;
    }
    
    return Vector3(
      sumX / totalWeight,
      sumY / totalWeight,
      sumZ / totalWeight,
    );
  }

  void _startNavigation(RoomLocation destination) async {
    // Establecer posición inicial alejada del destino para la demo
    // En producción, esto vendría del tracking AR real
    Vector3 startPos = _arService.currentPosition;
    
    // Si estamos muy cerca del destino, simular que empezamos desde lejos
    double distToDestination = startPos.distanceTo(destination.position);
    if (distToDestination < 3.0) {
      // Empezar desde 10 metros atrás en X y Z
      startPos = Vector3(
        destination.position.x - 10.0,
        destination.position.y,
        destination.position.z - 10.0,
      );
      _arService.setOrigin(Vector3.zero());
      _arService.updatePosition(startPos);
    }
    
    final success = await _navigationService.startNavigation(
      destination,
      startPosition: startPos,
    );
    
    if (success) {
      setState(() {
        _selectedDestination = destination;
        _isNavigating = true;
      });
      
      // Simular movimiento hacia el destino
      _arService.simulateMovementTowards(destination.position);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navegando hacia ${destination.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _stopNavigation() {
    _navigationService.stopNavigation();
    _arService.stopSimulation();
    
    setState(() {
      _isNavigating = false;
      _selectedDestination = null;
    });
  }

  void _onDestinationReached() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.arrivedMessage),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Vibrar (si está disponible)
    // Vibrate.feedback(FeedbackType.success);
    
    setState(() {
      _isNavigating = false;
      _selectedDestination = null;
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _cameraController?.dispose();
    _arService.stopSimulation();
    _arService.stopTracking();
    _navigationService.stopNavigation();
    super.dispose();
  }

  /// Widget para mostrar la vista AR con flecha de navegación
  Widget _buildCameraBackground() {
    // Si estamos navegando, usar el widget de flecha AR
    if (_isNavigating && _selectedDestination != null) {
      return ARNavigationArrow(
        destination: _selectedDestination!.position,
        currentPosition: _lastKnownPosition,
        distance: _currentDistance,
        useModel3D: _useModel3D,
        onSessionCreated: (sessionManager) {
          _arSessionManager = sessionManager;
          debugPrint('✅ Sesión AR conectada para navegación');
        },
        onPositionUpdated: (position) {
          // Actualizar posición desde el tracking AR real
          _arService.updatePosition(position);
        },
      );
    }
    
    // Vista AR sin navegación activa
    try {
      return _arService.getARCoreView(
        onViewCreated: (controller) {
          debugPrint('✅ Vista ARCore creada');
        },
        enableTapRecognizer: false,
      );
    } catch (e) {
      debugPrint('⚠️ ARCore no disponible, usando cámara: $e');
      
      // Fallback a cámara normal si ARCore falla
      if (_isCameraInitialized && _cameraController != null) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 100,
              height: _cameraController!.value.previewSize?.width ?? 100,
              child: CameraPreview(_cameraController!),
            ),
          ),
        );
      }
      
      // Fondo de respaldo si ni ARCore ni cámara están disponibles
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white30),
              SizedBox(height: 16),
              Text(
                'Cámara no disponible',
                style: TextStyle(color: Colors.white30),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Vista de cámara AR con flecha integrada
          _buildCameraBackground(),
          
          // Indicador de tracking (solo si NO estamos navegando, ya que la flecha AR lo muestra)
          if (!_isNavigating)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _arService.planesDetected
                        ? AppConstants.successColor
                        : AppConstants.warningColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _arService.planesDetected
                            ? Icons.check_circle
                            : Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _arService.planesDetected
                            ? 'Tracking Activo'
                            : 'Buscando planos...',
                        style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Panel de debug
          if (_debugMode)
            DebugPanel(
              debugInfo: {
                'AR Tracking': _arService.isTracking ? 'Activo' : 'Inactivo',
                'Planos': '${_arService.detectedPlanesCount}',
                'Posición': _lastKnownPosition.toString(),
                'Posición suavizada': 'Sí (${_positionHistory.length} muestras)',
                'Navegando': _isNavigating ? 'Sí' : 'No',
                'Distancia': '${_currentDistance.toStringAsFixed(2)}m',
                'Fuera de ruta': _isOffRoute ? 'Sí' : 'No',
                'Modelo 3D': _useModel3D ? 'Habilitado' : 'Deshabilitado',
              },
            ),
          
          // Botón de cerrar
          Positioned(
            top: 40,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Botón de debug
          Positioned(
            top: 40,
            right: 10,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() => _debugMode = !_debugMode);
                  _storageService.setDebugMode(_debugMode);
                },
              ),
            ),
          ),
          
          // Panel de navegación (bottom sheet)
          if (_isNavigating && _selectedDestination != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationPanel(
                destinationName: _selectedDestination!.name,
                distance: _currentDistance,
                estimatedTimeSeconds: _currentTime,
                isOffRoute: _isOffRoute,
                onStop: _stopNavigation,
              ),
            ),
          
          // Botón para seleccionar destino (si no está navegando)
          if (!_isNavigating)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _showDestinationSelector,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Seleccionar Destino'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDestinationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Selecciona tu destino',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: AppConstants.primaryColor,
                    ),
                    title: Text(location.name),
                    subtitle: Text(location.description),
                    onTap: () {
                      Navigator.pop(context);
                      _startNavigation(location);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
