import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/room_location.dart';
import '../services/storage_service.dart';
import '../services/ar_service.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

/// Pantalla de mapa 2D
/// Muestra vista cenital de las ubicaciones
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late StorageService _storageService;
  late ARService _arService;
  late NavigationService _navigationService;
  
  List<RoomLocation> _locations = [];
  Vector3? _currentPosition;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _arService = context.read<ARService>();
    _navigationService = context.read<NavigationService>();
    
    _loadData();
  }

  void _loadData() {
    setState(() {
      _locations = _storageService.getAllLocations();
      _currentPosition = _arService.currentPosition;
      _isNavigating = _navigationService.isNavigating;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa 2D'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _locations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ubicaciones para mostrar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Mapa
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _MapPainter(
                          locations: _locations,
                          currentPosition: _currentPosition,
                          navigationPath: _isNavigating
                              ? _navigationService.currentPath?.waypoints
                              : null,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                
                // Leyenda
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leyenda',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _LegendItem(
                            color: AppConstants.primaryColor,
                            label: 'Posición actual',
                            icon: Icons.my_location,
                          ),
                          _LegendItem(
                            color: Colors.red,
                            label: 'Destino',
                            icon: Icons.location_on,
                          ),
                          _LegendItem(
                            color: Colors.blue[300]!,
                            label: 'Ubicaciones',
                            icon: Icons.place,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Painter personalizado para dibujar el mapa 2D
class _MapPainter extends CustomPainter {
  final List<RoomLocation> locations;
  final Vector3? currentPosition;
  final List<Vector3>? navigationPath;

  _MapPainter({
    required this.locations,
    this.currentPosition,
    this.navigationPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey[100]!,
    );
    
    // Calcular límites del mapa
    double minX = 0, maxX = 0, minZ = 0, maxZ = 0;
    
    if (locations.isNotEmpty) {
      minX = locations.map((l) => l.posX).reduce(math.min);
      maxX = locations.map((l) => l.posX).reduce(math.max);
      minZ = locations.map((l) => l.posZ).reduce(math.min);
      maxZ = locations.map((l) => l.posZ).reduce(math.max);
      
      // Incluir posición actual en los límites
      if (currentPosition != null) {
        minX = math.min(minX, currentPosition!.x);
        maxX = math.max(maxX, currentPosition!.x);
        minZ = math.min(minZ, currentPosition!.z);
        maxZ = math.max(maxZ, currentPosition!.z);
      }
      
      // Añadir margen
      final marginX = (maxX - minX) * 0.2;
      final marginZ = (maxZ - minZ) * 0.2;
      minX -= marginX;
      maxX += marginX;
      minZ -= marginZ;
      maxZ += marginZ;
    }
    
    // Si todos están en el mismo punto, usar valores por defecto
    if (maxX - minX < 0.1) {
      minX = -5;
      maxX = 5;
    }
    if (maxZ - minZ < 0.1) {
      minZ = -5;
      maxZ = 5;
    }
    
    // Función para convertir coordenadas del mundo a coordenadas de pantalla
    Offset worldToScreen(double x, double z) {
      final screenX = ((x - minX) / (maxX - minX)) * size.width;
      final screenY = ((z - minZ) / (maxZ - minZ)) * size.height;
      return Offset(screenX, screenY);
    }
    
    // Dibujar grilla
    _drawGrid(canvas, size, minX, maxX, minZ, maxZ, worldToScreen);
    
    // Dibujar ruta de navegación
    if (navigationPath != null && navigationPath!.length > 1) {
      final pathPaint = Paint()
        ..color = AppConstants.pathLineColor.withOpacity(0.6)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      
      final path = Path();
      final firstPoint = worldToScreen(
        navigationPath!.first.x,
        navigationPath!.first.z,
      );
      path.moveTo(firstPoint.dx, firstPoint.dy);
      
      for (int i = 1; i < navigationPath!.length; i++) {
        final point = worldToScreen(
          navigationPath![i].x,
          navigationPath![i].z,
        );
        path.lineTo(point.dx, point.dy);
      }
      
      canvas.drawPath(path, pathPaint);
    }
    
    // Dibujar ubicaciones
    for (final location in locations) {
      final pos = worldToScreen(location.posX, location.posZ);
      
      // Círculo de ubicación
      canvas.drawCircle(
        pos,
        12,
        Paint()..color = Colors.blue[300]!,
      );
      
      // Borde
      canvas.drawCircle(
        pos,
        12,
        Paint()
          ..color = Colors.blue[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      
      // Nombre de la ubicación
      final textPainter = TextPainter(
        text: TextSpan(
          text: location.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy + 16),
      );
    }
    
    // Dibujar posición actual
    if (currentPosition != null) {
      final pos = worldToScreen(currentPosition!.x, currentPosition!.z);
      
      // Círculo exterior pulsante
      canvas.drawCircle(
        pos,
        20,
        Paint()
          ..color = AppConstants.primaryColor.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
      
      // Círculo interior
      canvas.drawCircle(
        pos,
        10,
        Paint()..color = AppConstants.primaryColor,
      );
      
      // Borde blanco
      canvas.drawCircle(
        pos,
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double minX,
    double maxX,
    double minZ,
    double maxZ,
    Offset Function(double, double) worldToScreen,
  ) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    
    // Líneas verticales cada metro
    final rangeX = maxX - minX;
    final stepX = rangeX > 20 ? 5.0 : rangeX > 10 ? 2.0 : 1.0;
    
    for (double x = (minX / stepX).ceil() * stepX; x <= maxX; x += stepX) {
      final start = worldToScreen(x, minZ);
      final end = worldToScreen(x, maxZ);
      canvas.drawLine(start, end, gridPaint);
    }
    
    // Líneas horizontales cada metro
    final rangeZ = maxZ - minZ;
    final stepZ = rangeZ > 20 ? 5.0 : rangeZ > 10 ? 2.0 : 1.0;
    
    for (double z = (minZ / stepZ).ceil() * stepZ; z <= maxZ; z += stepZ) {
      final start = worldToScreen(minX, z);
      final end = worldToScreen(maxX, z);
      canvas.drawLine(start, end, gridPaint);
    }
    
    // Ejes principales (origen)
    final originPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2;
    
    // Eje X (horizontal)
    final originXStart = worldToScreen(minX, 0);
    final originXEnd = worldToScreen(maxX, 0);
    canvas.drawLine(originXStart, originXEnd, originPaint);
    
    // Eje Z (vertical)
    final originZStart = worldToScreen(0, minZ);
    final originZEnd = worldToScreen(0, maxZ);
    canvas.drawLine(originZStart, originZEnd, originPaint);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.navigationPath != navigationPath;
  }
}
