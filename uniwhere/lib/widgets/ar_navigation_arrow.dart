import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import '../utils/constants.dart';

/// Widget que muestra una flecha 3D AR que apunta hacia el destino
class ARNavigationArrow extends StatefulWidget {
  final Vector3 destination;
  final Vector3 currentPosition;
  final double distance;
  final Function(ARSessionManager)? onSessionCreated;
  final Function(Vector3)? onPositionUpdated;
  final bool useModel3D;

  const ARNavigationArrow({
    super.key,
    required this.destination,
    required this.currentPosition,
    required this.distance,
    this.onSessionCreated,
    this.onPositionUpdated,
    this.useModel3D = true,
  });

  @override
  State<ARNavigationArrow> createState() => _ARNavigationArrowState();
}

class _ARNavigationArrowState extends State<ARNavigationArrow>
    with SingleTickerProviderStateMixin {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  // ignore: unused_field
  ARLocationManager? _arLocationManager;

  ARNode? _arrowNode;
  ARAnchor? _arrowAnchor;
  
  bool _arViewReady = false;
  bool _model3DAvailable = false;
  bool _model3DLoaded = false;
  Timer? _updateTimer;
  
  // Para la flecha 2D animada de respaldo
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _checkModel3DAvailable();
    
    // Animación de respaldo para flecha 2D
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkModel3DAvailable() async {
    // Usar modelo 3D que seguirá la cámara
    if (widget.useModel3D) {
      debugPrint('🎯 Modelo 3D habilitado - usará getCameraPose para seguir cámara');
      setState(() => _model3DAvailable = true);
    } else {
      setState(() => _model3DAvailable = false);
    }
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _arSessionManager = sessionManager;
    _arObjectManager = objectManager;
    _arAnchorManager = anchorManager;
    _arLocationManager = locationManager;
    
    debugPrint('✅ AR View creada - inicializando sesión...');

    // Inicializar sesión AR
    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: false,
      showAnimatedGuide: false,
    );
    
    _arObjectManager!.onInitialize();
    
    setState(() => _arViewReady = true);
    debugPrint('✅ AR View lista - _arViewReady = true');
    
    widget.onSessionCreated?.call(sessionManager);
    
    // Iniciar actualización de flecha después de un delay para asegurar que AR esté listo
    Future.delayed(const Duration(milliseconds: 500), () {
      _startArrowUpdates();
    });
  }

  void _startArrowUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 100), // Actualizar frecuentemente para seguir la cámara
      (_) => _updateArrowPosition(),
    );
  }

  Future<void> _updateArrowPosition() async {
    if (!_arViewReady || _arObjectManager == null || _arSessionManager == null) return;

    // La flecha siempre apunta al norte (ángulo 0)
    const double northAngle = 0.0;
    
    // Obtener la pose actual de la cámara
    Matrix4? cameraPose = await _arSessionManager!.getCameraPose();
    if (cameraPose == null) return;
    
    // Extraer posición de la cámara
    Vector3 cameraPosition = Vector3(
      cameraPose.getColumn(3).x,
      cameraPose.getColumn(3).y,
      cameraPose.getColumn(3).z,
    );
    
    // Extraer dirección "forward" de la cámara (columna Z negativa)
    Vector3 cameraForward = Vector3(
      -cameraPose.getColumn(2).x,
      -cameraPose.getColumn(2).y,
      -cameraPose.getColumn(2).z,
    ).normalized();
    
    // Posicionar la flecha 4m frente a la cámara (más lejos = parece más pequeña)
    Vector3 arrowPosition = cameraPosition + (cameraForward * 9.0);
    arrowPosition.y -= 0.5; // Ligeramente abajo del nivel de ojos

    // Actualizar o crear el nodo de la flecha
    if (_arrowNode == null && _model3DAvailable) {
      await _createArrowNode(arrowPosition, northAngle);
    } else if (_arrowNode != null) {
      // Actualizar posición del nodo para seguir la cámara
      await _updateArrowTransform(arrowPosition, northAngle);
    }
  }

  Future<void> _createArrowNode(Vector3 position, double angle) async {
    try {
      debugPrint('🎯 ============================================');
      debugPrint('🎯 Creando nodo de flecha 3D (seguirá cámara)');
      debugPrint('🎯 Posición inicial: $position');
      debugPrint('🎯 Ángulo: $angle rad (${angle * 180 / math.pi}°) - APUNTANDO AL NORTE');
      debugPrint('🎯 Escala aplicada: 0.0001 (extremadamente pequeña)');
      debugPrint('🎯 ============================================');
      
      // Crear nodo AR con modelo GLB
      _arrowNode = ARNode(
        type: NodeType.localGLB,
        uri: "assets/models/arrow.glb",
        scale: Vector3.all(0.0001), // Escala extremadamente reducida
        position: position,
        eulerAngles: Vector3(0, angle, 0),
        name: 'navigation_arrow_3d',
      );

      // Añadir directamente a la escena sin anchor
      debugPrint('🎯 Añadiendo nodo a AR Object Manager (sin anchor)...');
      bool? didAdd = await _arObjectManager?.addNode(_arrowNode!);
      
      debugPrint('🎯 Resultado de addNode: $didAdd');
      
      if (didAdd == true) {
        debugPrint('✅ ¡Flecha 3D añadida correctamente!');
        setState(() => _model3DLoaded = true);
      } else {
        debugPrint('⚠️ addNode retornó: $didAdd');
        debugPrint('⚠️ El modelo puede no haberse cargado correctamente');
        _arrowNode = null;
        // No deshabilitamos 3D, intentaremos de nuevo
      }
    } on PlatformException catch (e) {
      debugPrint('❌ PlatformException al crear flecha 3D:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Details: ${e.details}');
      _arrowNode = null;
      setState(() => _model3DAvailable = false);
    } catch (e, stackTrace) {
      debugPrint('❌ Error genérico al crear flecha 3D: $e');
      debugPrint('Stack trace: $stackTrace');
      _arrowNode = null;
      setState(() => _model3DAvailable = false);
    }
  }

  Future<void> _updateArrowTransform(Vector3 position, double angle) async {
    if (_arrowNode == null || _arObjectManager == null) return;
    
    try {
      // Remover el nodo anterior
      await _arObjectManager!.removeNode(_arrowNode!);
      
      // Crear nuevo nodo en la nueva posición (frente a la cámara)
      _arrowNode = ARNode(
        type: NodeType.localGLB,
        uri: "assets/models/arrow.glb",
        scale: Vector3.all(0.0001), // Escala extremadamente reducida
        position: position, // Posición calculada frente a la cámara
        eulerAngles: Vector3(0, angle, 0), // Rota para apuntar al norte (angle = 0)
        name: 'navigation_arrow_3d',
      );
      
      await _arObjectManager!.addNode(_arrowNode!);
    } catch (e) {
      debugPrint('Error actualizando flecha: $e');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    
    // Limpiar nodos AR
    if (_arrowNode != null && _arObjectManager != null) {
      _arObjectManager!.removeNode(_arrowNode!);
    }
    
    _arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vista AR de fondo (la flecha 3D se renderiza aquí si está cargada)
        ARView(
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
        ),
        
        // Flecha 2D animada como respaldo (solo cuando 3D no está cargada)
        if (!_model3DLoaded)
          Center(
            child: _buildAnimated2DArrow(),
          ),
        
        // Overlay de información
        _buildInfoOverlay(),
      ],
    );
  }

  Widget _buildAnimated2DArrow() {
    // Calcular ángulo hacia el destino
    Vector3 direction = widget.destination - widget.currentPosition;
    double angle = math.atan2(direction.x, direction.z);
    
    // Color basado en distancia
    Color arrowColor = AppConstants.getArrowColorByDistance(widget.distance);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Transform.rotate(
              angle: -angle, // Rotar hacia el destino
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: arrowColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo de fondo con gradiente
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            arrowColor.withOpacity(0.8),
                            arrowColor.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    
                    // Flecha principal
                    CustomPaint(
                      size: const Size(80, 100),
                      painter: _ArrowPainter(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                    ),
                    
                    // Borde brillante
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Distancia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              AppConstants.formatDistance(widget.distance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Indicador de tracking
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AR Tracking Activo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter personalizado para dibujar una flecha estilizada
class _ArrowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArrowPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = strokeWidth;

    final path = Path();
    
    // Dibujar flecha apuntando hacia arriba
    final centerX = size.width / 2;
    
    // Punta de la flecha
    path.moveTo(centerX, 0);
    
    // Lado derecho de la punta
    path.lineTo(centerX + size.width * 0.4, size.height * 0.4);
    
    // Entrante derecho
    path.lineTo(centerX + size.width * 0.15, size.height * 0.35);
    
    // Cuerpo derecho
    path.lineTo(centerX + size.width * 0.15, size.height);
    
    // Base
    path.lineTo(centerX - size.width * 0.15, size.height);
    
    // Cuerpo izquierdo
    path.lineTo(centerX - size.width * 0.15, size.height * 0.35);
    
    // Entrante izquierdo
    path.lineTo(centerX - size.width * 0.4, size.height * 0.4);
    
    // Cerrar hacia la punta
    path.close();

    canvas.drawPath(path, paint);
    
    // Borde
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
