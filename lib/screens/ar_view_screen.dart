import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/waypoint.dart';
import '../widgets/ar_overlay.dart';

class ARViewScreen extends StatefulWidget {
  final Waypoint destination;
  final Waypoint currentLocation;

  const ARViewScreen({
    super.key,
    required this.destination,
    required this.currentLocation,
  });

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  double _deviceHeading = 0.0; // Device compass heading
  double _devicePitch = 0.0; // Device tilt
  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;
  List<double> _accelerometerValues = [0, 0, 0];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró ninguna cámara')),
          );
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar cámara: $e')),
        );
      }
    }
  }

  void _initializeSensors() {
    // Listen to magnetometer for compass heading
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      // Calculate heading from magnetometer data
      final heading = math.atan2(event.y, event.x) * (180 / math.pi);
      if (mounted) {
        setState(() {
          _deviceHeading = (heading + 360) % 360;
        });
      }
    });

    // Listen to accelerometer for device tilt
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (mounted) {
        setState(() {
          _accelerometerValues = [event.x, event.y, event.z];
          // Calculate pitch (forward/backward tilt)
          _devicePitch = math.atan2(event.y, math.sqrt(event.x * event.x + event.z * event.z)) * (180 / math.pi);
        });
      }
    });
  }

  double _calculateBearing() {
    // Calculate bearing from current location to destination
    final dx = widget.destination.latitude - widget.currentLocation.latitude;
    final dy = widget.destination.longitude - widget.currentLocation.longitude;
    final bearing = math.atan2(dy, dx) * (180 / math.pi);
    return (bearing + 360) % 360;
  }

  double _calculateDistance() {
    // Calculate simple euclidean distance
    final dx = widget.destination.latitude - widget.currentLocation.latitude;
    final dy = widget.destination.longitude - widget.currentLocation.longitude;
    final dz = widget.destination.altitude - widget.currentLocation.altitude;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bearing = _calculateBearing();
    final distance = _calculateDistance();
    final relativeBearing = (bearing - _deviceHeading + 360) % 360;

    return Scaffold(
      appBar: AppBar(
        title: Text('Navegando a ${widget.destination.name}'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          
          // AR Overlay with navigation indicators
          if (_isCameraInitialized)
            AROverlay(
              destination: widget.destination,
              bearing: relativeBearing,
              distance: distance,
              devicePitch: _devicePitch,
            ),
          
          // Info panel at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.place,
                        widget.destination.name,
                        Colors.blue,
                      ),
                      _buildInfoItem(
                        Icons.straighten,
                        '${distance.toStringAsFixed(1)}m',
                        Colors.green,
                      ),
                      _buildInfoItem(
                        Icons.explore,
                        '${relativeBearing.toStringAsFixed(0)}°',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getNavigationInstruction(relativeBearing),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getNavigationInstruction(double bearing) {
    if (bearing > 345 || bearing < 15) {
      return 'Continúa recto';
    } else if (bearing >= 15 && bearing < 75) {
      return 'Gira ligeramente a la derecha';
    } else if (bearing >= 75 && bearing < 105) {
      return 'Gira a la derecha';
    } else if (bearing >= 105 && bearing < 165) {
      return 'Gira fuertemente a la derecha';
    } else if (bearing >= 165 && bearing < 195) {
      return 'Da la vuelta';
    } else if (bearing >= 195 && bearing < 255) {
      return 'Gira fuertemente a la izquierda';
    } else if (bearing >= 255 && bearing < 285) {
      return 'Gira a la izquierda';
    } else {
      return 'Gira ligeramente a la izquierda';
    }
  }
}
