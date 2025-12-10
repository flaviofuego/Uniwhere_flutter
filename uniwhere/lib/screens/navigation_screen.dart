import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:camera/camera.dart';
import '../models/room_location.dart';
import '../services/ar_service.dart';
import '../services/navigation_service.dart';
import '../services/storage_service.dart';
import '../widgets/navigation_panel.dart';
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
  
  bool _isInitialized = false;
  bool _isNavigating = false;
  bool _debugMode = false;
  Timer? _updateTimer;
  
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

  @override
  void initState() {
    super.initState();
    _arService = context.read<ARService>();
    _navigationService = context.read<NavigationService>();
    _storageService = context.read<StorageService>();
    
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
      // Inicializar cámara
      await _initializeCamera();
      
      // Inicializar AR
      await _arService.initialize();
      await _arService.startTracking();
      
      // Cargar ubicaciones
      _locations = _storageService.getAllLocations();
      
      // Cargar modo debug
      _debugMode = _storageService.getDebugMode();
      
      // Establecer origen si no está configurado
      if (!_arService.originSet) {
        _arService.setOrigin(Vector3.zero());
      }
      
      // Iniciar simulación de movimiento para testing
      _arService.startSimulation(startPosition: Vector3.zero());
      
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
    
    // Actualizar posición en el servicio de navegación
    _navigationService.updatePosition(_arService.currentPosition);
    
    // Actualizar estado
    setState(() {
      _currentDistance = _navigationService.getRemainingDistance();
      _currentTime = _navigationService.getRemainingTime();
      _isOffRoute = _navigationService.isOffRoute();
    });
  }

  void _startNavigation(RoomLocation destination) async {
    final success = await _navigationService.startNavigation(
      destination,
      startPosition: _arService.currentPosition,
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

  /// Widget para mostrar la vista de cámara o un fondo de respaldo
  Widget _buildCameraBackground() {
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
    
    // Fondo de respaldo si la cámara no está disponible
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
          // Vista de cámara real o fondo de respaldo
          _buildCameraBackground(),
          
          // Indicador de tracking
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
          
          // Simulación de flecha AR apuntando al destino
          if (_isNavigating && _selectedDestination != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 100,
                    color: AppConstants.getArrowColorByDistance(_currentDistance),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppConstants.formatDistance(_currentDistance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Destino: ${_selectedDestination!.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Panel de debug
          if (_debugMode)
            DebugPanel(
              debugInfo: {
                'AR Tracking': _arService.isTracking ? 'Activo' : 'Inactivo',
                'Planos': '${_arService.detectedPlanesCount}',
                'Posición': _arService.currentPosition.toString(),
                'Navegando': _isNavigating ? 'Sí' : 'No',
                'Distancia': '${_currentDistance.toStringAsFixed(2)}m',
                'Fuera de ruta': _isOffRoute ? 'Sí' : 'No',
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
