import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../config.dart';
import '../models/waypoint.dart';
import '../models/navigation_pose.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';

/// Pantalla principal de navegación AR.
///
/// Flujo de localización (cada [AppConfig.localizationIntervalMs] ms):
///   1. Captura un snapshot de la vista AR
///   2. POST /localize → obtenemos NavigationPose (posición en el mapa + nodo)
///   3. GET /route → obtenemos la lista de waypoints
///   4. Actualiza las flechas 3D AR con la nueva dirección
///
/// La pantalla usa [ARView] de ar_flutter_plugin_plus para el fondo de cámara
/// y coloca nodos 3D (flechas GLB) en el espacio AR para guiar al usuario.
class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================================
  // MANAGERS DE AR
  // ============================================================================
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  // _arAnchorManager se guarda para uso futuro (anclajes en el suelo)
  ARAnchorManager? _arAnchorManager; // ignore: unused_field

  // ============================================================================
  // ESTADO DE AR
  // ============================================================================
  bool _arReady = false;
  // ignore: prefer_final_fields  - mutable: se actualiza si AR falla en inicialización
  bool _arError = false;
  // ignore: prefer_final_fields
  String _arErrorMsg = '';

  // Nodo de flecha AR actualmente en escena
  ARNode? _arrowNode;

  // ============================================================================
  // TIMER DE LOCALIZACIÓN
  // ============================================================================
  Timer? _localizationTimer;

  // Guard para evitar llamadas concurrentes de localización
  bool _isLocalizing = false;

  // Último ángulo usado para la flecha AR (para evitar updates innecesarios)
  double _lastArrowAngle = double.nan;

  // ============================================================================
  // ANIMACIÓN DE FLECHA 2D (overlay de respaldo)
  // ============================================================================
  late AnimationController _arrowAnimController;
  late Animation<double> _bounceAnim;
  late Animation<double> _pulseAnim;

  // ============================================================================
  // ESTADO UI
  // ============================================================================
  bool _showDebugPanel = false;

  @override
  void initState() {
    super.initState();

    // Mantener pantalla encendida durante la navegación
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Animación de la flecha 2D
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _arrowAnimController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _arrowAnimController, curve: Curves.easeInOut),
    );

    // Iniciar timer de localización cuando el AR esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLocalizationTimer());

    // Leer el modo debug desde settings
    _showDebugPanel = context.read<SettingsProvider>().debugMode;
  }

  @override
  void dispose() {
    _localizationTimer?.cancel();
    _arrowAnimController.dispose();
    _arSessionManager?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ============================================================================
  // INICIALIZACIÓN DEL TIMER DE LOCALIZACIÓN
  // ============================================================================

  void _startLocalizationTimer() {
    // Usamos un timer encadenado (delay-based) en vez de periódico para que
    // no se acumulen llamadas si el procesamiento tarda más que el intervalo.
    _scheduleNextLocalization();
  }

  void _scheduleNextLocalization() {
    _localizationTimer = Timer(
      const Duration(milliseconds: AppConfig.localizationIntervalMs),
      () async {
        await _performLocalization();
        // Programar el siguiente ciclo sólo si la pantalla sigue montada
        if (mounted) _scheduleNextLocalization();
      },
    );
  }

  /// Captura un frame de la vista AR y llama al backend para localizar
  Future<void> _performLocalization() async {
    // Evitar llamadas concurrentes que saturan la CPU y traban la cámara
    if (_isLocalizing) return;
    if (_arSessionManager == null || !_arReady) return;

    final nav = context.read<NavigationProvider>();
    if (!nav.isNavigating) return;

    _isLocalizing = true;
    try {
      // Capturar snapshot de la vista AR actual.
      // snapshot() devuelve ImageProvider<Object> en ar_flutter_plugin_plus ^1.0.0
      // Necesitamos convertirlo a Uint8List para enviarlo al backend.
      Uint8List? imageBytes;
      try {
        final imageProvider = await _arSessionManager!.snapshot();
        imageBytes = await _imageProviderToBytes(imageProvider);
      } catch (e) {
        debugPrint('[AR] Error capturando snapshot: $e');
        return;
      }

      if (imageBytes == null || imageBytes.isEmpty) return;

      // Redimensionar a 1280×720.
      // Esta resolución debe coincidir con la usada al grabar los videos
      // con el smartphone para generar el mapa con COLMAP; de lo contrario
      // los descriptores SuperPoint extraídos en el backend no coincidirán.
      final processedBytes = await _resizeAndCompressJpeg(imageBytes, 1280, 720);
      imageBytes = processedBytes ?? imageBytes;

      // Enviar al backend y actualizar ruta
      await nav.localizeAndUpdateRoute(imageBytes);

      // Actualizar flecha AR con la nueva dirección (sólo si cambió significativamente)
      if (mounted) _updateArArrow(nav);
    } finally {
      _isLocalizing = false;
    }
  }

  // ============================================================================
  // HELPER: REDIMENSIONAR Y COMPRIMIR A JPEG
  // ============================================================================

  /// Redimensiona [srcBytes] (PNG) a [targetW]×[targetH] píxeles.
  ///
  /// Flutter no expone compresión JPEG nativa en dart:ui; se re-codifica
  /// como PNG. El backend acepta PNG además de JPEG.
  /// Devuelve null si ocurre cualquier error.
  Future<Uint8List?> _resizeAndCompressJpeg(
    Uint8List srcBytes,
    int targetW,
    int targetH,
  ) async {
    try {
      // Decodificar y redimensionar en un solo paso
      final codec = await ui.instantiateImageCodec(
        srcBytes,
        targetWidth: targetW,
        targetHeight: targetH,
      );
      final frame = await codec.getNextFrame();
      final resized = frame.image;

      // Codificar como PNG (un solo encode, sin pasos intermedios inútiles)
      final pngData = await resized.toByteData(format: ui.ImageByteFormat.png);
      resized.dispose();
      codec.dispose();
      return pngData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[AR] Error al redimensionar imagen: $e');
      return null;
    }
  }

  // ============================================================================
  // HELPER: CONVERTIR ImageProvider A Uint8List
  // ============================================================================

  /// Convierte un ImageProvider (devuelto por snapshot()) a bytes PNG.
  /// Necesario para enviar el frame al backend FastAPI como multipart/form-data.
  Future<Uint8List?> _imageProviderToBytes(ImageProvider imageProvider) async {
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    final completer = Completer<ui.Image>();
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (imageInfo, _) {
        if (!completer.isCompleted) {
          completer.complete(imageInfo.image);
        }
        imageStream.removeListener(listener);
      },
      onError: (error, stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
        imageStream.removeListener(listener);
      },
    );

    imageStream.addListener(listener);

    final uiImage = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('Timeout al obtener imagen del AR'),
    );

    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // ============================================================================
  // GESTIÓN DEL NODO FLECHA EN AR
  // ============================================================================

  /// Actualiza o crea el nodo de flecha AR apuntando al siguiente waypoint.
  /// Solo recrea el nodo si la dirección cambió más de 10 grados para evitar
  /// churn innecesario en la sesión AR que traba la cámara.
  Future<void> _updateArArrow(NavigationProvider nav) async {
    if (_arObjectManager == null || nav.nextWaypoint == null) return;

    final pose = nav.lastPose;
    final waypoint = nav.nextWaypoint!;

    // Calcular dirección y ángulo hacia el waypoint desde la pose actual
    final angle = pose != null
        ? _calculateAngleToWaypoint(pose, waypoint)
        : 0.0;

    // Si el ángulo no cambió más de 10°, no vale la pena recrear el nodo AR
    const thresholdRad = 0.175; // ~10 grados en radianes
    if (_arrowNode != null &&
        !_lastArrowAngle.isNaN &&
        (angle - _lastArrowAngle).abs() < thresholdRad) {
      return;
    }
    _lastArrowAngle = angle;

    // Eliminar el nodo anterior antes de agregar el nuevo
    if (_arrowNode != null) {
      try {
        await _arObjectManager!.removeNode(_arrowNode!);
      } catch (_) {}
      _arrowNode = null;
    }

    // Posición de la flecha: delante del usuario a 1.5 m, a altura de 1 m
    final arrowPosition = Vector3(
      math.sin(angle) * 1.5, // desplazamiento lateral
      0.0,                    // misma altura que el suelo (ajustado con y en el modelo)
      -math.cos(angle) * 1.5, // hacia adelante
    );

    // Rotación del nodo en el eje Y para que apunte hacia el destino
    final arrowRotation = Vector4(0, 1, 0, angle); // eje Y, ángulo calculado

    try {
      _arrowNode = ARNode(
        type: NodeType.localGLB,
        uri: 'models/arrow.glb', // relativo a la carpeta assets/ de Flutter
        scale: Vector3(0.3, 0.3, 0.3),
        position: arrowPosition,
        rotation: arrowRotation,
      );
      await _arObjectManager!.addNode(_arrowNode!);
    } catch (e) {
      debugPrint('[AR] Error colocando nodo flecha: $e');
      _arrowNode = null;
    }
  }

  /// Calcula el ángulo horizontal (en el plano XZ) desde la pose del usuario
  /// hacia el waypoint destino, en coordenadas del mapa.
  double _calculateAngleToWaypoint(NavigationPose pose, Waypoint waypoint) {
    final dx = waypoint.x - pose.x;
    final dz = waypoint.z - pose.z;
    return math.atan2(dx, dz);
  }

  // ============================================================================
  // CALLBACK DEL AR VIEW
  // ============================================================================

  void _onArViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    // Configurar la sesión AR sin detección de planos (no necesario para navegación)
    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: false,
      handleRotation: false,
    );

    _arObjectManager!.onInitialize();

    setState(() => _arReady = true);
    debugPrint('[AR] Sesión AR inicializada correctamente');
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ====================================================================
          // CAPA 1: Vista AR (cámara + tracking + nodos 3D)
          // ====================================================================
          _buildArView(),

          // ====================================================================
          // CAPA 2: Overlay de navegación
          // ====================================================================
          if (_arReady && !_arError) _buildNavigationOverlay(),

          // ====================================================================
          // CAPA 3: Estado de error AR
          // ====================================================================
          if (_arError) _buildArErrorOverlay(),

          // ====================================================================
          // CAPA 4: Botón de cancelar (siempre visible)
          // ====================================================================
          _buildCancelButton(),

          // ====================================================================
          // CAPA 5: Panel inferior con info de navegación
          // ====================================================================
          _buildBottomPanel(),

          // ====================================================================
          // CAPA 6: Panel de debug (opcional)
          // ====================================================================
          if (_showDebugPanel) _buildDebugPanel(),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET: VISTA AR
  // ============================================================================

  Widget _buildArView() {
    if (_arError) {
      // Si AR no está disponible, mostrar fondo negro con mensaje
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                _arErrorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ARView(
      onARViewCreated: _onArViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.none,
    );
  }

  // ============================================================================
  // WIDGET: OVERLAY DE NAVEGACIÓN (flecha 2D + indicador de localización)
  // ============================================================================

  Widget _buildNavigationOverlay() {
    return Consumer<NavigationProvider>(
      builder: (context, nav, _) {
        return Stack(
          children: [
            // Indicador de "Localizando..." en la parte superior
            _buildLocalizingIndicator(nav),

            // Flecha 2D de dirección (overlay sobre la cámara AR)
            // Se usa como guía visual mientras los nodos 3D se actualizan
            if (nav.isNavigating && nav.lastPose != null)
              _buildDirectionArrow(nav),
          ],
        );
      },
    );
  }

  /// Banner superior que muestra el estado de localización
  Widget _buildLocalizingIndicator(NavigationProvider nav) {
    if (!nav.isLocalizing && nav.localizationStatus != LocalizationStatus.error) {
      return const SizedBox.shrink();
    }

    final isError = nav.localizationStatus == LocalizationStatus.error;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(isError),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.withValues(alpha:0.85)
                : Colors.black.withValues(alpha:0.75),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isError)
                SpinKitThreeBounce(
                  color: Colors.white,
                  size: 18,
                )
              else
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  isError
                      ? (nav.localizationError ?? 'Apunta la cámara hacia el pasillo con buena iluminación. Evita apuntar a paredes lisas o zonas sin textura visual.')
                      : 'Localizando...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Flecha 2D animada que apunta hacia el siguiente waypoint.
  /// Se dibuja en el centro de la pantalla con rotación calculada.
  Widget _buildDirectionArrow(NavigationProvider nav) {
    final pose = nav.lastPose!;
    final waypoint = nav.nextWaypoint;
    if (waypoint == null) return const SizedBox.shrink();

    final angle = _calculateAngleToWaypoint(pose, waypoint);
    final dist = nav.estimatedDistanceToDestination;
    final color = AppConfig.arrowColorByDistance(dist);

    return Positioned(
      // Posición: centro de la pantalla, ligeramente arriba
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.28,
      child: Center(
        child: AnimatedBuilder(
          animation: _arrowAnimController,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -_bounceAnim.value),
            child: Transform.scale(
              scale: _pulseAnim.value,
              child: Transform.rotate(
                angle: angle,
                child: _Arrow2DWidget(color: color, size: 110),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET: BOTÓN CANCELAR
  // ============================================================================

  Widget _buildCancelButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      child: SafeArea(
        child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET: PANEL INFERIOR DE INFORMACIÓN
  // ============================================================================

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Consumer<NavigationProvider>(
        builder: (context, nav, _) => _NavigationBottomPanel(nav: nav),
      ),
    );
  }

  // ============================================================================
  // WIDGET: PANEL DE DEBUG
  // ============================================================================

  Widget _buildDebugPanel() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 12,
      child: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          final pose = nav.lastPose;
          if (pose == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha:0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              pose.debugText,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // WIDGET: OVERLAY DE ERROR AR
  // ============================================================================

  Widget _buildArErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_in_ar, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'AR no disponible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _arErrorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Se requiere ARCore. Asegúrate de tener ARCore Services instalado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// WIDGET: FLECHA 2D PERSONALIZADA
// ==============================================================================

/// Dibuja una flecha estilizada 2D usando CustomPaint.
/// Se usa como overlay sobre la vista AR.
class _Arrow2DWidget extends StatelessWidget {
  final Color color;
  final double size;

  const _Arrow2DWidget({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.45),
            blurRadius: 24,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo circular semi-transparente
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha:0.75),
                  color.withValues(alpha:0.25),
                ],
              ),
            ),
          ),
          // Flecha dibujada con CustomPaint
          CustomPaint(
            size: Size(size * 0.55, size * 0.68),
            painter: _ArrowPainter(color: Colors.white),
          ),
          // Borde brillante
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha:0.4),
                width: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter de la flecha hacia arriba (el widget padre maneja la rotación)
class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final path = Path();

    // Punta superior
    path.moveTo(cx, 0);
    // Ala derecha
    path.lineTo(cx + size.width * 0.44, size.height * 0.42);
    // Entrante derecho del cuerpo
    path.lineTo(cx + size.width * 0.16, size.height * 0.36);
    // Base derecha
    path.lineTo(cx + size.width * 0.16, size.height);
    // Base izquierda
    path.lineTo(cx - size.width * 0.16, size.height);
    // Entrante izquierdo del cuerpo
    path.lineTo(cx - size.width * 0.16, size.height * 0.36);
    // Ala izquierda
    path.lineTo(cx - size.width * 0.44, size.height * 0.42);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}

// ==============================================================================
// WIDGET: PANEL INFERIOR DE NAVEGACIÓN
// ==============================================================================

class _NavigationBottomPanel extends StatelessWidget {
  final NavigationProvider nav;

  const _NavigationBottomPanel({required this.nav});

  @override
  Widget build(BuildContext context) {
    final destination = nav.selectedDestination;
    if (destination == null) return const SizedBox.shrink();

    final dist = nav.estimatedDistanceToDestination;
    final remaining = nav.remainingWaypoints;
    final color = AppConfig.arrowColorByDistance(dist);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.12),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Destino actual
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppConfig.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navegando a',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),

              // Stats: distancia y waypoints restantes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    icon: Icons.straighten_rounded,
                    value: AppConfig.formatDistance(dist),
                    label: 'Distancia',
                    color: color,
                  ),
                  _StatChip(
                    icon: Icons.schedule_rounded,
                    value: AppConfig.formatWalkTime(dist),
                    label: 'Tiempo',
                    color: Colors.white70,
                  ),
                  _StatChip(
                    icon: Icons.pin_drop_outlined,
                    value: '$remaining',
                    label: 'Waypoints',
                    color: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de estadística para el panel inferior
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}
