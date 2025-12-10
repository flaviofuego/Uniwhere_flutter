# AR Home Navigator Demo

Aplicación de demostración en Flutter que simula un sistema de **AR Wayfinding + VPS** (Visual Positioning System) para navegación interior. Este prototipo está diseñado para demostrar la viabilidad de un sistema de navegación AR en campus universitario.

## 🎯 Características Principales

### 1. AR Wayfinding (Navegación con Realidad Aumentada)
- ✅ Detección de planos horizontales simulada
- ✅ Sistema de waypoints/rutas entre ubicaciones
- ✅ Flechas 3D que guían al destino
- ✅ Indicador de distancia y dirección en tiempo real
- ✅ Código de color según proximidad (verde/amarillo/rojo)

### 2. VPS Simulado (Sistema de Posicionamiento Visual)
- ✅ Framework para reconocimiento de imágenes de referencia
- ✅ Capacidad de relocalization
- ✅ Ajuste de posición al detectar puntos de referencia
- ✅ Notificaciones de actualización de posición

### 3. Fichas de Información AR
- ✅ Paneles flotantes con información de ubicaciones
- ✅ Datos de habitaciones (nombre, descripción, características)
- ✅ Botones interactivos ("Navegar aquí", "Cerrar")
- ✅ Animaciones suaves de aparición/desaparición

### 4. Modo Calibración
- ✅ Mapeo de espacios interiores
- ✅ Marcado de puntos de interés
- ✅ Captura de fotos de referencia para VPS
- ✅ Sistema de categorización de ubicaciones

### 5. Mapa 2D
- ✅ Vista cenital del espacio mapeado
- ✅ Visualización de posición actual
- ✅ Ruta trazada durante navegación
- ✅ Grilla de referencia con coordenadas

## 📋 Requisitos del Sistema

### Dispositivos Compatibles
- **Android:** Versión 7.0 (API 24) o superior con soporte ARCore
- **iOS:** iOS 11.0 o superior con soporte ARKit
- Cámara funcional
- Giroscopio y acelerómetro
- Al menos 2GB de RAM

### Software Necesario
- Flutter SDK 3.9.2 o superior
- Android Studio / Xcode
- Dispositivo físico (emuladores no soportan AR completamente)

## 🚀 Instalación

### 1. Clonar el Repositorio
```bash
git clone https://github.com/flaviofuego/Uniwhere_flutter.git
cd Uniwhere_flutter/uniwhere
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configuración Android
```bash
# Verificar que tu dispositivo esté conectado
flutter devices

# Ejecutar en dispositivo Android
flutter run
```

### 4. Configuración iOS
```bash
cd ios
pod install
cd ..

# Ejecutar en dispositivo iOS
flutter run
```

## 📱 Guía de Uso

### Primera Ejecución

1. **Otorgar Permisos**
   - La app solicitará permiso de cámara
   - Permiso de almacenamiento para fotos de referencia
   - Aceptar todos los permisos para funcionalidad completa

2. **Modo Calibración**
   - Toca "Modo Calibración" en la pantalla de inicio
   - Camina por tu casa/espacio
   - Presiona el botón flotante "+" para marcar ubicaciones
   - Completa el formulario:
     * Nombre de la ubicación
     * Categoría (Habitación, Servicio, Recreación, Trabajo)
     * Descripción breve
     * (Opcional) Tomar foto de referencia
   - Repite para cada ubicación importante
   - Presiona "Finalizar Calibración" cuando termines

3. **Modo Navegación**
   - Vuelve a la pantalla de inicio
   - Selecciona una ubicación de la lista
   - O toca "Modo Navegación" y elige un destino
   - Sigue las flechas AR hacia tu destino
   - La flecha cambia de color según la distancia:
     * 🟢 Verde: < 3 metros (cerca)
     * 🟡 Amarillo: 3-10 metros (medio)
     * 🔴 Rojo: > 10 metros (lejos)

4. **Ver Mapa 2D**
   - Toca el ícono de mapa en la parte superior
   - Visualiza todas las ubicaciones mapeadas
   - Ve tu posición actual y ruta activa

### Funciones Avanzadas

**Modo Debug:**
- Toca el ícono de bug en las pantallas AR
- Muestra información técnica:
  * Estado de tracking AR
  * Número de planos detectados
  * Coordenadas actuales (X, Y, Z)
  * Distancia al destino
  * Estado de navegación

**Búsqueda:**
- Usa la barra de búsqueda en inicio
- Busca por nombre, descripción o tags
- Resultados filtrados en tiempo real

**Gestión de Ubicaciones:**
- Máximo 20 ubicaciones permitidas
- Puedes editar o eliminar ubicaciones desde configuración
- Reset completo disponible en configuración

## 🏗️ Arquitectura del Proyecto

```
lib/
├── models/              # Modelos de datos
│   ├── room_location.dart
│   ├── navigation_path.dart
│   ├── ar_info_card.dart
│   └── sample_data.dart
│
├── services/            # Lógica de negocio
│   ├── ar_service.dart
│   ├── navigation_service.dart
│   ├── vps_service.dart
│   ├── storage_service.dart
│   └── permissions_service.dart
│
├── screens/             # Pantallas principales
│   ├── home_screen.dart
│   ├── calibration_screen.dart
│   ├── navigation_screen.dart
│   └── map_screen.dart
│
├── widgets/             # Componentes reutilizables
│   ├── location_card.dart
│   ├── navigation_panel.dart
│   ├── debug_panel.dart
│   └── ar_info_card_widget.dart
│
├── utils/               # Utilidades y helpers
│   ├── constants.dart
│   ├── vector3_helper.dart
│   └── pathfinding_helper.dart
│
└── main.dart            # Punto de entrada
```

## 🔧 Tecnologías Utilizadas

### Dependencias Principales
- `ar_flutter_plugin`: Framework AR para Flutter
- `vector_math`: Cálculos matemáticos 3D
- `hive`: Base de datos local NoSQL
- `provider`: Gestión de estado
- `image_picker`: Captura de fotos
- `google_mlkit_image_labeling`: Reconocimiento de imágenes
- `permission_handler`: Gestión de permisos

### Algoritmos Implementados
- **Pathfinding:** A* simplificado para cálculo de rutas
- **Interpolación:** Catmull-Rom para rutas suaves
- **Vector Math:** Operaciones 3D para posicionamiento AR

## 🎨 Personalización

### Colores
Edita `lib/utils/constants.dart`:
```dart
static const Color primaryColor = Color(0xFF2196F3);  // Azul
static const Color successColor = Color(0xFF4CAF50);  // Verde
static const Color warningColor = Color(0xFFFFC107);  // Amarillo
```

### Configuración de Navegación
```dart
// Distancia para considerar "llegada"
static const double destinationThreshold = 1.0;  // metros

// Velocidad de caminata promedio
static const double walkingSpeed = 1.4;  // m/s

// Máximo de ubicaciones
static const int maxLocations = 20;
```

### Datos de Ejemplo
Modifica `lib/models/sample_data.dart` para cambiar las ubicaciones precargadas.

## 🐛 Troubleshooting

### Problema: "Camera permission denied"
**Solución:** Ve a Configuración > Apps > AR Home Navigator > Permisos y habilita la cámara.

### Problema: "AR tracking no funciona"
**Solución:**
- Asegúrate de estar en un lugar bien iluminado
- Mueve el dispositivo lentamente para detectar planos
- El dispositivo debe soportar ARCore (Android) o ARKit (iOS)

### Problema: "App se cierra al iniciar AR"
**Solución:**
- Verifica que estés usando un dispositivo físico (no emulador)
- Actualiza Google Play Services for AR (Android)
- Reinicia el dispositivo

### Problema: "No se guardan las ubicaciones"
**Solución:**
- Verifica permisos de almacenamiento
- Revisa que no hayas alcanzado el límite de 20 ubicaciones
- Limpia datos de la app y vuelve a intentar

### Problema: Compilación falla en iOS
**Solución:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

## 📊 Limitaciones Conocidas

1. **AR Simulado:** Esta versión usa AR simulado para demostración. Para producción se requiere integración completa con ARCore/ARKit.

2. **VPS Simplificado:** El reconocimiento de imágenes es básico. Para producción se recomienda usar Google ARCore Cloud Anchors o similar.

3. **Pathfinding Básico:** Usa línea directa sin considerar obstáculos. Para espacios complejos se requiere implementar A* completo con detección de obstáculos.

4. **Escalabilidad:** Optimizado para espacios de 5-20 metros (casa típica). Para campus requiere optimizaciones de rendimiento.

## 🚀 Próximos Pasos para Producción

1. **Integración AR Real:**
   - Implementar `arcore_flutter_plugin` para Android
   - Implementar `arkit_plugin` para iOS
   - Detección real de planos y tracking

2. **VPS Avanzado:**
   - Integrar Google ARCore Cloud Anchors
   - Reconocimiento robusto de imágenes con ML Kit
   - Sincronización en la nube

3. **Networking:**
   - Backend para compartir mapas entre usuarios
   - Sincronización de ubicaciones
   - Analytics y telemetría

4. **Mejoras UX:**
   - Tutorial interactivo en primera ejecución
   - Modo offline con mapas precargados
   - Accesibilidad (guía por voz, vibración)

5. **Campus Universitario:**
   - Escalabilidad para espacios grandes (>100m)
   - Múltiples edificios y pisos
   - Integración con horarios de clases
   - Rutas accesibles (rampas, elevadores)

## 📄 Licencia

Este proyecto es un prototipo de demostración. Consulta el archivo LICENSE para más detalles.

## 👥 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📧 Contacto

Para preguntas o soporte, contacta a través del repositorio de GitHub.

## 🙏 Agradecimientos

- Flutter Team por el excelente framework
- Comunidad de ARCore y ARKit
- Contribuidores de paquetes de código abierto

---

**Nota:** Este es un prototipo de demostración. No está optimizado para uso en producción sin las mejoras mencionadas en "Próximos Pasos".

