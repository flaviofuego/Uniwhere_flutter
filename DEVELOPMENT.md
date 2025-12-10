# Guía de Desarrollo - AR Wayfinding

Esta guía proporciona información técnica para desarrolladores que quieran extender o modificar el proyecto.

## 🏗️ Arquitectura

### Estructura de Carpetas

```
lib/
├── main.dart                    # Entry point, permission handling
├── models/                      # Data models
│   ├── waypoint.dart           # Waypoint entity
│   └── waypoint_data.dart      # Sample data provider
├── screens/                     # UI screens
│   ├── home_screen.dart        # Destination selection
│   └── ar_view_screen.dart     # AR navigation view
└── widgets/                     # Reusable widgets
    └── ar_overlay.dart         # AR visualization overlay

test/
└── waypoint_test.dart          # Unit tests

android/                         # Android specific config
ios/                            # iOS specific config
```

## 📚 Componentes Principales

### 1. Waypoint Model (`models/waypoint.dart`)

Representa un punto de interés o destino.

```dart
class Waypoint {
  final String id;
  final String name;
  final String description;
  final double latitude;    // X coordinate
  final double longitude;   // Y coordinate
  final double altitude;    // Z coordinate (height)
  final IconData icon;

  // Methods:
  // - distanceTo(Waypoint other): Calculate euclidean distance
  // - bearingTo(Waypoint other): Calculate angle to destination
}
```

**Key Methods:**
- `distanceTo()`: Euclidean distance formula
- `bearingTo()`: Arctangent calculation for angle

### 2. Home Screen (`screens/home_screen.dart`)

Pantalla principal de selección de destinos.

**Features:**
- Lista de waypoints disponibles
- Selección de destino
- Navegación a vista AR

**State Management:**
- `_selectedDestination`: Waypoint seleccionado
- `_currentLocation`: Ubicación actual del usuario

### 3. AR View Screen (`screens/ar_view_screen.dart`)

Vista principal de navegación AR.

**Components:**
- Camera preview
- Sensor listeners (magnetometer, accelerometer)
- AR overlay rendering
- Navigation instructions

**Key State:**
```dart
CameraController _cameraController;
double _deviceHeading;     // Compass direction (0-360°)
double _devicePitch;       // Device tilt angle
```

**Sensor Integration:**
- **Magnetometer**: Compass heading
- **Accelerometer**: Device tilt/pitch

**Navigation Logic:**
```dart
bearing = atan2(dy, dx) * 180 / PI
relativeBearing = (bearing - deviceHeading + 360) % 360
distance = sqrt(dx² + dy² + dz²)
```

### 4. AR Overlay (`widgets/ar_overlay.dart`)

Renderiza elementos AR sobre la cámara.

**Components:**
- Destination marker (when in FOV)
- Navigation arrow
- Distance indicator

**CustomPainters:**
- `ARArrowPainter`: Dibuja flecha de navegación
- `DownArrowPainter`: Flecha apuntando al marcador

## 🔧 Configuración por Plataforma

### Android

**Minimum SDK**: 24 (Android 7.0)
**Target SDK**: 34 (Android 14)

**Archivos clave:**
- `android/app/build.gradle`: Configuración de build
- `android/app/src/main/AndroidManifest.xml`: Permisos y features
- `android/app/src/main/kotlin/.../MainActivity.kt`: Activity principal

**Permisos:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS

**Minimum Deployment**: iOS 12.0

**Archivos clave:**
- `ios/Runner/Info.plist`: Configuración y permisos

**Privacy Descriptions:**
```xml
<key>NSCameraUsageDescription</key>
<string>Esta aplicación necesita acceso a la cámara para la navegación AR</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a tu ubicación para la navegación</string>
```

## 📦 Dependencias

### Core Dependencies

```yaml
camera: ^0.10.5+5              # Camera access
permission_handler: ^11.0.1    # Runtime permissions
sensors_plus: ^4.0.2           # Accelerometer, magnetometer
vector_math: ^2.1.4            # Vector calculations
flutter_compass: ^0.8.0        # Compass functionality
geolocator: ^10.1.0            # Location services
ar_flutter_plugin: ^0.7.3      # AR capabilities
```

### Dev Dependencies

```yaml
flutter_test:                  # Testing framework
  sdk: flutter
flutter_lints: ^3.0.0          # Linting rules
```

## 🧪 Testing

### Ejecutar Tests

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/waypoint_test.dart

# Run with coverage
flutter test --coverage
```

### Test Coverage

Current tests cover:
- ✅ Waypoint model creation
- ✅ Distance calculations
- ✅ Bearing calculations
- ✅ Waypoint data retrieval

**TODO:**
- [ ] UI widget tests
- [ ] Integration tests
- [ ] Sensor mock tests

## 🔍 Debugging

### Habilitar Logs

En `main.dart`, agrega:

```dart
import 'package:flutter/foundation.dart';

debugPrint('Your debug message');
```

### Debug Camera Issues

```dart
// In ar_view_screen.dart
print('Camera initialized: $_isCameraInitialized');
print('Available cameras: ${await availableCameras()}');
```

### Debug Sensor Data

```dart
// In ar_view_screen.dart
print('Heading: $_deviceHeading°');
print('Pitch: $_devicePitch°');
print('Accelerometer: $_accelerometerValues');
```

## 🎨 Personalización

### Agregar Nuevo Destino

1. Edita `lib/models/waypoint_data.dart`:

```dart
static final List<Waypoint> sampleWaypoints = [
  // ... existing waypoints
  Waypoint(
    id: '6',
    name: 'Nuevo Lugar',
    description: 'Descripción del lugar',
    latitude: 2.5,
    longitude: 3.5,
    altitude: 0.0,
    icon: Icons.new_releases,
  ),
];
```

2. Hot reload la aplicación

### Cambiar Colores del AR

En `lib/widgets/ar_overlay.dart`:

```dart
// Cambiar color de flecha
final paint = Paint()
  ..color = Colors.red.withOpacity(0.7)  // Cambiar aquí
  ..style = PaintingStyle.fill;

// Cambiar color de marcador
Container(
  decoration: BoxDecoration(
    color: Colors.green.withOpacity(0.9),  // Cambiar aquí
    // ...
  ),
)
```

### Ajustar Sensibilidad de Sensores

En `lib/screens/ar_view_screen.dart`:

```dart
// Cambiar frecuencia de actualización
_magnetometerSubscription = magnetometerEventStream(
  samplingPeriod: Duration(milliseconds: 100),  // Ajustar aquí
).listen((event) { ... });
```

### Modificar Instrucciones de Navegación

En `lib/screens/ar_view_screen.dart`:

```dart
String _getNavigationInstruction(double bearing) {
  // Ajustar rangos de ángulos
  if (bearing > 345 || bearing < 15) {
    return 'Tu instrucción personalizada';
  }
  // ...
}
```

## 🚀 Extensiones Futuras

### Integración con GPS Real

```dart
// Usar geolocator para posición real
import 'package:geolocator/geolocator.dart';

Position position = await Geolocator.getCurrentPosition();
Waypoint currentLocation = Waypoint(
  id: 'current',
  name: 'Current',
  description: 'Current location',
  latitude: position.latitude,
  longitude: position.longitude,
  altitude: position.altitude,
);
```

### Agregar Mapas

```dart
// Usar google_maps_flutter o flutter_map
import 'package:google_maps_flutter/google_maps_flutter.dart';

GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(latitude, longitude),
    zoom: 15,
  ),
  markers: waypointsToMarkers(),
)
```

### Persistencia de Datos

```dart
// Usar shared_preferences o sqflite
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveWaypoint(Waypoint waypoint) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('waypoint_${waypoint.id}', 
    jsonEncode(waypoint.toJson()));
}
```

### ARCore/ARKit Integration

Para AR más avanzado:

```dart
// Usar ar_flutter_plugin o arcore_flutter_plugin
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

ARView(
  onARViewCreated: onARViewCreated,
  planeDetectionConfig: PlaneDetectionConfig.horizontal,
)
```

## 📊 Performance Tips

### Optimizar Renders

```dart
// Usar const constructors cuando sea posible
const Icon(Icons.place)

// Evitar rebuilds innecesarios
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  // ...
}
```

### Reducir Frecuencia de Sensores

```dart
// En lugar de actualizar en cada evento
Timer.periodic(Duration(milliseconds: 100), (timer) {
  // Update UI
});
```

### Lazy Loading de Waypoints

```dart
// Si tienes muchos waypoints
List<Waypoint> get visibleWaypoints {
  return allWaypoints.where((w) => 
    w.distanceTo(currentLocation) < maxVisibleDistance
  ).toList();
}
```

## 🐛 Common Issues

### Issue: "PlatformException: Camera"

**Causa**: Permisos no otorgados
**Solución**: Verificar permisos en AndroidManifest.xml y Info.plist

### Issue: Sensor data not updating

**Causa**: Device no tiene sensores o están deshabilitados
**Solución**: 
```dart
try {
  _magnetometerSubscription = magnetometerEventStream().listen(...);
} catch (e) {
  print('Magnetometer not available: $e');
}
```

### Issue: Camera preview distorted

**Causa**: Aspect ratio incorrecto
**Solución**:
```dart
AspectRatio(
  aspectRatio: _cameraController.value.aspectRatio,
  child: CameraPreview(_cameraController),
)
```

## 📖 Recursos Adicionales

### Documentation
- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [Sensors Plus Plugin](https://pub.dev/packages/sensors_plus)
- [AR Flutter Plugin](https://pub.dev/packages/ar_flutter_plugin)

### Tutorials
- [Building AR Apps with Flutter](https://flutter.dev/docs)
- [Indoor Positioning Techniques](https://www.indooratlas.com/)

### Communities
- [Flutter Discord](https://discord.gg/flutter)
- [Flutter Reddit](https://reddit.com/r/FlutterDev)

## 🤝 Contributing Guidelines

Si quieres contribuir:

1. Fork el repositorio
2. Crea una rama feature: `git checkout -b feature/amazing-feature`
3. Sigue las convenciones de código
4. Agrega tests para nuevas features
5. Actualiza documentación
6. Submit a PR

### Code Style

- Usa `dart format` antes de commit
- Sigue las reglas de `analysis_options.yaml`
- Prefiere `const` constructors
- Documenta funciones públicas

```dart
/// Calcula la distancia euclidiana entre dos waypoints.
///
/// Retorna la distancia al cuadrado para evitar sqrt costoso.
/// Usa [other] como punto de destino.
double distanceTo(Waypoint other) {
  // ...
}
```

## 📝 License

MIT License - Ver archivo LICENSE para más detalles.

---

**Happy Coding!** 🚀
