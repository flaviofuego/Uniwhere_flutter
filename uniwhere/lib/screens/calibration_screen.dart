import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/room_location.dart';
import '../models/sample_data.dart';
import '../services/ar_service.dart';
import '../services/storage_service.dart';
import '../services/vps_service.dart';
import '../utils/constants.dart';
import '../widgets/debug_panel.dart';

/// Pantalla de calibración para mapear la casa
/// Permite marcar puntos de interés y tomar fotos de referencia
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  late ARService _arService;
  late StorageService _storageService;
  late VPSService _vpsService;
  
  bool _isInitialized = false;
  bool _debugMode = false;
  List<RoomLocation> _markedLocations = [];
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _arService = context.read<ARService>();
    _storageService = context.read<StorageService>();
    _vpsService = context.read<VPSService>();
    
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Inicializar servicios
      await _arService.initialize();
      await _arService.startTracking();
      await _vpsService.initialize();
      
      // Cargar ubicaciones ya guardadas
      _markedLocations = _storageService.getAllLocations();
      
      // Cargar modo debug
      _debugMode = _storageService.getDebugMode();
      
      // Establecer origen si no está configurado
      if (!_arService.originSet) {
        _arService.setOrigin(Vector3.zero());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Origen establecido en tu posición actual'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      // Simular movimiento para testing
      _arService.startSimulation();
      
      setState(() => _isInitialized = true);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _arService.stopSimulation();
    _arService.stopTracking();
    super.dispose();
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
          // Fondo simulado de cámara AR
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[800]!,
                  Colors.blue[900]!,
                ],
              ),
            ),
          ),
          
          // Retícula de guía
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),
          
          // Instrucciones
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_searching,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.calibrationMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubicaciones marcadas: ${_markedLocations.length}/${AppConstants.maxLocations}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Panel de debug
          if (_debugMode)
            DebugPanel(
              debugInfo: {
                'AR Tracking': _arService.isTracking ? 'Activo' : 'Inactivo',
                'Planos': '${_arService.detectedPlanesCount}',
                'Posición': _arService.currentPosition.toString(),
                'Ubicaciones': '${_markedLocations.length}',
              },
            ),
          
          // Botón de cerrar
          Positioned(
            top: 40,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                  size: 30,
                ),
                onPressed: () {
                  setState(() => _debugMode = !_debugMode);
                  _storageService.setDebugMode(_debugMode);
                },
              ),
            ),
          ),
          
          // Botón de marcar punto
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _markedLocations.length >= AppConstants.maxLocations
                    ? null
                    : _showMarkLocationDialog,
                backgroundColor: _markedLocations.length >= AppConstants.maxLocations
                    ? Colors.grey
                    : AppConstants.primaryColor,
                child: const Icon(Icons.add_location, size: 40),
              ),
            ),
          ),
          
          // Lista de ubicaciones marcadas (deslizable)
          Positioned(
            right: 10,
            top: 120,
            bottom: 200,
            width: 60,
            child: _markedLocations.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _markedLocations.length,
                      itemBuilder: (context, index) {
                        final location = _markedLocations[index];
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            backgroundColor: AppConstants.primaryColor,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          
          // Botón de finalizar
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: ElevatedButton.icon(
              onPressed: _finishCalibration,
              icon: const Icon(Icons.check),
              label: const Text('Finalizar Calibración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkLocationDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    String category = 'recreacion';
    String? imagePath;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marcar Ubicación'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Cocina',
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.length > AppConstants.maxLocationNameLength) {
                        return 'Máximo ${AppConstants.maxLocationNameLength} caracteres';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  
                  // Descripción
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Descripción breve',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value != null && value.length > AppConstants.maxDescriptionLength) {
                        return 'Máximo ${AppConstants.maxDescriptionLength} caracteres';
                      }
                      return null;
                    },
                    onSaved: (value) => description = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  
                  // Categoría
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: SampleData.getCategories().map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(_getCategoryDisplayName(cat)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => category = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón para foto de referencia
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        setDialogState(() => imagePath = image.path);
                      }
                    },
                    icon: Icon(
                      imagePath != null ? Icons.check_circle : Icons.camera_alt,
                    ),
                    label: Text(
                      imagePath != null
                          ? 'Foto tomada'
                          : 'Tomar foto de referencia',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context);
                  _saveLocation(name, description, category, imagePath);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLocation(
    String name,
    String description,
    String category,
    String? imagePath,
  ) async {
    try {
      // Crear ubicación con posición actual del AR
      final location = RoomLocation(
        id: SampleData.generateId(),
        name: name,
        description: description,
        posX: _arService.currentPosition.x,
        posY: _arService.currentPosition.y,
        posZ: _arService.currentPosition.z,
        category: category,
        iconPath: SampleData.getCategoryIcons()[category]!,
        tags: [],
        imageReference: imagePath,
      );
      
      // Guardar en storage
      await _storageService.saveLocation(location);
      
      // Si hay imagen, registrar en VPS
      if (imagePath != null) {
        await _vpsService.registerReferenceLocation(location, imagePath);
        await _storageService.saveReferenceImage(location.id, imagePath);
      }
      
      setState(() {
        _markedLocations.add(location);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicación "$name" guardada'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _finishCalibration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Calibración'),
        content: Text(
          '¿Has terminado de mapear tu casa?\n\n'
          'Ubicaciones marcadas: ${_markedLocations.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a home
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'habitacion':
        return 'Habitación';
      case 'servicio':
        return 'Servicio';
      case 'recreacion':
        return 'Recreación';
      case 'trabajo':
        return 'Trabajo';
      default:
        return category;
    }
  }
}

/// Painter para dibujar retícula de guía
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    
    // Líneas verticales
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Líneas horizontales
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Cruz central
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 20),
      Offset(size.width / 2, size.height / 2 + 20),
      centerPaint,
    );
    
    canvas.drawLine(
      Offset(size.width / 2 - 20, size.height / 2),
      Offset(size.width / 2 + 20, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
