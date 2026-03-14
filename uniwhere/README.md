# UNIwhere

Sistema de **navegación indoor con Realidad Aumentada** para campus universitarios. La app localiza al usuario dentro del edificio comparando la imagen de la cámara contra un mapa 3D reconstruido con COLMAP, y lo guía con flechas AR hasta el destino.

## Arquitectura del sistema

```
Smartphone (Flutter)
        │  frame JPEG 1280×720
        ▼
Backend FastAPI (localhost:8000)
        │  SuperPoint + SuperGlue (hloc)
        │  Pose estimada contra modelo COLMAP
        ▼
Mapa 3D del campus
(COLMAP · SIMPLE_RADIAL · videos smartphone)
```

**Backend endpoints:**

| Método | Ruta | Descripción |
|--------|------|-------------|
| `POST` | `/localize` | Recibe imagen → devuelve pose 3D + nodo más cercano |
| `GET`  | `/route?origin=X&destination=Y` | Devuelve lista de waypoints entre dos nodos |
| `GET`  | `/points_of_interest` | Devuelve todos los nodos del mapa |

## Pantallas

| Pantalla | Descripción |
|----------|-------------|
| **SplashScreen** | Logo animado, carga inicial |
| **HomeScreen** | Lista de destinos desde `/points_of_interest`, búsqueda, indicador de conexión al backend |
| **ARNavigationScreen** | Vista AR en tiempo real, flechas 3D/2D, localización cada 2 s vía `/localize` |
| **SettingsScreen** | IP del backend configurable, modo debug (muestra coordenadas de pose) |

## Requisitos

### Dispositivo
- Android 7.0 (API 24) o superior
- ARCore Services instalado
- Cámara trasera funcional

### Backend
- Python con FastAPI corriendo en la misma red WiFi
- Modelo COLMAP del campus generado con videos de smartphone
- hloc con SuperPoint + SuperGlue para localización visual

### Desarrollo
- Flutter SDK 3.9.2 o superior
- Dispositivo físico (los emuladores no soportan AR)

## Instalación

```bash
git clone https://github.com/flaviofuego/Uniwhere_flutter.git
cd Uniwhere_flutter/uniwhere
flutter pub get
flutter run
```

En iOS, antes de `flutter run`:
```bash
cd ios && pod install && cd ..
```

## Configuración

Al iniciar la app por primera vez, ir a **Configuración** e ingresar la IP del backend:

```
http://192.168.x.x:8000
```

Usar el botón **"Probar conexión"** para verificar que el backend responde antes de navegar.

## Flujo de localización

1. `ARView` inicializa la sesión ARCore (sin detección de planos).
2. Un `Timer` dispara cada **2 segundos**:
   - Captura un snapshot de la vista AR (`arSessionManager.snapshot()`).
   - Redimensiona el frame a **1280×720** para que coincida con la resolución de los videos usados en COLMAP.
   - `POST /localize` → el backend corre SuperPoint + SuperGlue y devuelve la pose en coordenadas del mapa.
   - `GET /route` → lista de waypoints desde el nodo más cercano hasta el destino.
3. Se coloca un nodo GLB (`arrow.glb`) en el espacio AR apuntando al siguiente waypoint.
4. Un overlay 2D animado refuerza la dirección visualmente mientras los nodos 3D se actualizan.

> **Importante:** la resolución del frame enviado al backend (1280×720) debe coincidir con la resolución de los videos grabados para generar el mapa COLMAP. Si se regrabó el mapa con otra resolución, actualizar las constantes en `ARNavigationScreen._resizeAndCompressJpeg`.

## Estructura del proyecto

```
lib/
├── config.dart                   # Colores, URLs, constantes COLMAP
├── main.dart                     # Entry point, MultiProvider
│
├── models/
│   ├── waypoint.dart             # Nodo del grafo {id, x, y, z}
│   ├── point_of_interest.dart    # POI con nombre, categoría, edificio
│   └── navigation_pose.dart      # Resultado de /localize (pose + nearest_node)
│
├── services/
│   └── backend_service.dart      # HTTP: /localize, /route, /points_of_interest
│
├── providers/
│   ├── navigation_provider.dart  # Estado central (POIs, ruta, pose, conexión)
│   └── settings_provider.dart    # IP backend + debug mode → SharedPreferences
│
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── ar_navigation_screen.dart
│   └── settings_screen.dart
│
└── widgets/
    └── ar_navigation_arrow.dart  # Flecha AR (nodo 3D + fallback 2D animado)
```

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| `ar_flutter_plugin_plus` | ARCore / ARKit |
| `http` | Llamadas al backend FastAPI |
| `provider` | Estado global |
| `shared_preferences` | Persistencia de IP y modo debug |
| `flutter_spinkit` | Indicadores de carga |
| `vector_math` | Matemáticas 3D para posicionamiento AR |

## Personalización

**Cambiar colores universitarios** → `lib/config.dart`:
```dart
static const Color primaryColor = Color(0xFF003087); // Azul universitario
```

**Cambiar resolución de localización** → `lib/screens/ar_navigation_screen.dart`:
```dart
final processedBytes = await _resizeAndCompressJpeg(bytes, 1280, 720, 70);
// Ajustar 1280×720 a la resolución usada al grabar los videos COLMAP
```

**Cambiar IP del backend en tiempo de compilación** → `lib/config.dart`:
```dart
static const String defaultBaseUrl = 'http://192.168.1.10:8000';
```

## Troubleshooting

**La localización siempre falla**
- Verifica que la IP del backend sea correcta en Configuración.
- Apunta la cámara hacia un pasillo con textura visual, no hacia paredes lisas.
- Confirma que la resolución de grabación de los videos COLMAP sea 1280×720.

**AR no inicia / pantalla negra**
- Instala o actualiza Google Play Services for AR desde la Play Store.
- Usa un dispositivo físico; los emuladores no soportan ARCore.
- Verifica que Impeller esté deshabilitado (ya configurado en `AndroidManifest.xml`).

**"No se puede conectar al servidor"**
- El smartphone y el servidor deben estar en la misma red WiFi.
- Confirmar que el backend FastAPI esté corriendo: `uvicorn main:app --host 0.0.0.0 --port 8000`.

**Compilación falla en iOS**
```bash
cd ios && pod deintegrate && pod install && cd ..
flutter clean && flutter pub get && flutter run
```

## Licencia

Consulta el archivo LICENSE para más detalles.
