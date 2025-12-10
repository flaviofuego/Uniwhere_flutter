# Guía de Desarrollo - AR Home Navigator

## Resumen Técnico

Esta aplicación es un prototipo funcional de un sistema de navegación interior con AR y VPS. Aunque usa simulaciones para algunos componentes AR, toda la arquitectura y lógica está preparada para integración real.

## Arquitectura de Servicios

### ARService (lib/services/ar_service.dart)
**Responsabilidad:** Gestionar sesión AR, tracking y posicionamiento.

**Métodos Principales:**
- `initialize()` - Inicializa sesión AR
- `startTracking()` - Inicia tracking de planos
- `updatePosition(Vector3)` - Actualiza posición del usuario
- `setOrigin(Vector3)` - Establece punto de origen del sistema de coordenadas

**Para Producción:**
- Reemplazar simulación con `ar_flutter_plugin`
- Implementar detección real de planos
- Añadir gestión de anclajes AR

### NavigationService (lib/services/navigation_service.dart)
**Responsabilidad:** Cálculo de rutas y gestión de navegación.

**Métodos Principales:**
- `startNavigation(RoomLocation)` - Inicia navegación a destino
- `updatePosition(Vector3)` - Actualiza posición y verifica llegada
- `calculatePath(Vector3, Vector3)` - Calcula ruta entre dos puntos
- `recalculateRoute()` - Recalcula ruta si se desvía

**Algoritmos Usados:**
- Pathfinding directo (línea recta)
- A* con grid (preparado para obstáculos)
- Interpolación Catmull-Rom para rutas suaves

### VPSService (lib/services/vps_service.dart)
**Responsabilidad:** Sistema de posicionamiento visual.

**Métodos Principales:**
- `registerReferenceLocation()` - Registra imagen de referencia
- `recognizeOnce()` - Reconocimiento único de imagen
- `startContinuousRecognition()` - Reconocimiento continuo

**Para Producción:**
- Integrar Google ML Kit Image Labeling
- Usar ARCore Cloud Anchors
- Implementar matching de features SIFT/ORB

### StorageService (lib/services/storage_service.dart)
**Responsabilidad:** Persistencia local con Hive.

**Métodos Principales:**
- `saveLocation(RoomLocation)` - Guarda ubicación
- `getAllLocations()` - Obtiene todas las ubicaciones
- `searchLocationsByName(String)` - Búsqueda por nombre
- `clearAllData()` - Limpia todos los datos

**Base de Datos:**
- Hive (NoSQL, local)
- 3 boxes: locations, images, settings

## Modelos de Datos

### RoomLocation
**Propiedades clave:**
```dart
String id, name, description, category
double posX, posY, posZ  // Coordenadas 3D
List<String> tags
String? imageReference   // Para VPS
```

**Métodos útiles:**
- `distanceTo(RoomLocation)` - Calcula distancia
- `getCategoryColor()` - Retorna color de categoría

### NavigationPath
**Propiedades clave:**
```dart
List<Vector3> waypoints
double totalDistance
int estimatedTimeSeconds
```

**Métodos útiles:**
- `getNextWaypoint(Vector3)` - Siguiente punto en ruta
- `getRemainingDistance(Vector3)` - Distancia restante
- `hasReachedDestination(Vector3)` - Verifica llegada

## Patrones de Diseño Utilizados

### Provider (Inyección de Dependencias)
```dart
MultiProvider(
  providers: [
    Provider<ARService>(create: (_) => ARService()),
    Provider<NavigationService>(create: (_) => NavigationService()),
    // ...
  ],
)
```

### Singleton Services
Todos los servicios son singleton gestionados por Provider.

### Observer Pattern
Los servicios usan callbacks para notificar cambios:
```dart
navigationService.onDestinationReached = () { /* handle */ };
navigationService.onDistanceChanged = (distance) { /* update UI */ };
```

## Flujos Principales

### Flujo de Calibración
1. Usuario abre CalibrationScreen
2. AR tracking inicia
3. Usuario camina y marca ubicaciones
4. Para cada ubicación:
   - Se captura posición actual del AR
   - Se toma foto opcional (VPS)
   - Se guarda en Storage
5. Finaliza calibración

### Flujo de Navegación
1. Usuario selecciona destino en HomeScreen
2. NavigationScreen inicia
3. NavigationService calcula ruta
4. Loop de actualización:
   - AR actualiza posición
   - Navigation verifica distancia
   - UI muestra flechas/indicadores
5. Al llegar: notificación + vibración

## Optimizaciones Implementadas

### Performance
- Actualización de posición cada 100ms (no cada frame)
- Simplificación de rutas con Douglas-Peucker
- Límite de 20 ubicaciones
- Modo bajo consumo (FPS reducido)

### UX
- Animaciones suaves (300ms)
- Debouncing en búsqueda
- Feedback háptico (vibración)
- Colores semánticos (verde/amarillo/rojo)

## Testing

### Testing Sin Dispositivo AR
El código incluye simulaciones para testing:
```dart
_arService.startSimulation();  // Simula movimiento
_arService.simulateMovementTowards(target);  // Movimiento hacia objetivo
```

### Modo Debug
Activa con el ícono de bug para ver:
- Coordenadas en tiempo real
- Estado de tracking
- Distancia a destino
- FPS

## Extensión para Campus Universitario

### Cambios Necesarios

**1. Escalabilidad Espacial:**
```dart
// Aumentar rango de renderizado
static const double maxRenderDistance = 500.0;  // campus grande

// Múltiples pisos
class RoomLocation {
  int floor;  // Añadir piso
  String building;  // Añadir edificio
}
```

**2. Navegación Entre Edificios:**
```dart
// Pathfinding con grafo de edificios
class CampusGraph {
  Map<String, List<String>> buildingConnections;
  // A* entre edificios
}
```

**3. Sincronización Cloud:**
```dart
// Backend para compartir ubicaciones
class CloudSync {
  Future<void> uploadLocation(RoomLocation);
  Future<List<RoomLocation>> downloadCampusLocations();
}
```

**4. Integración con Horarios:**
```dart
class ClassSchedule {
  String classroom;
  DateTime startTime;
  // Sugerir navegación antes de clase
}
```

## Comandos Útiles

### Desarrollo
```bash
flutter run --debug                 # Ejecutar en debug
flutter run --release              # Ejecutar optimizado
flutter run --profile              # Profiling
```

### Build
```bash
flutter build apk                   # Android APK
flutter build appbundle            # Android App Bundle
flutter build ios                   # iOS
```

### Testing
```bash
flutter test                        # Unit tests
flutter test --coverage            # Con cobertura
```

### Generación de Código (Hive)
```bash
flutter pub run build_runner build  # Generar adaptadores
flutter pub run build_runner watch  # Watch mode
```

## Solución de Problemas Comunes

### Error: "Hive box not found"
**Causa:** No se generaron los adaptadores de Hive.
**Solución:** 
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Provider not found"
**Causa:** Widget no está dentro del árbol de Provider.
**Solución:** Asegurar que el widget esté dentro de MultiProvider en main.dart.

### Error: "Null check operator"
**Causa:** Servicio no inicializado antes de uso.
**Solución:** Verificar que `initialize()` se llame en initState.

## Recursos Adicionales

### Documentación de Paquetes
- [ar_flutter_plugin](https://pub.dev/packages/ar_flutter_plugin)
- [vector_math](https://pub.dev/packages/vector_math)
- [hive](https://pub.dev/packages/hive)
- [provider](https://pub.dev/packages/provider)

### Tutoriales Recomendados
- [ARCore Fundamentals](https://developers.google.com/ar/develop)
- [ARKit Documentation](https://developer.apple.com/arkit/)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)

### Herramientas
- [Blender](https://www.blender.org/) - Modelado 3D
- [GIMP](https://www.gimp.org/) - Edición de imágenes
- [VS Code](https://code.visualstudio.com/) - IDE recomendado

## Contribuciones

Al contribuir, por favor:
1. Mantén los comentarios en español
2. Sigue la estructura de carpetas existente
3. Documenta métodos públicos
4. Añade tests para lógica compleja
5. Actualiza README si añades features
