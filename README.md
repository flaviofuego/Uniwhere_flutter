# AR Wayfinding - Uniwhere Flutter

Sistema de navegación en Realidad Aumentada (AR) para interiores usando Flutter. Perfecto para pruebas en ambientes como tu casa u oficina.

## 🎯 Características

- **Navegación AR en tiempo real**: Usa la cámara del dispositivo para mostrar indicaciones visuales
- **Brújula y sensores**: Integración con magnetómetro y acelerómetro para orientación precisa
- **Waypoints predefinidos**: Sistema de puntos de interés para navegación
- **Interfaz intuitiva**: Indicadores visuales claros y instrucciones de navegación en español
- **Fácil de probar**: Configurado con waypoints de ejemplo para simular habitaciones de una casa

## 📋 Requisitos Previos

- Flutter SDK 3.0.0 o superior
- Dart 3.0.0 o superior
- Android Studio / Xcode (para desarrollo móvil)
- Dispositivo físico con cámara (el emulador no soporta AR completo)

## 🚀 Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/flaviofuego/Uniwhere_flutter.git
cd Uniwhere_flutter
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar en dispositivo**
```bash
# Para Android
flutter run

# Para iOS
flutter run
```

## 📱 Uso

### Primera Ejecución

1. Al abrir la app, se solicitarán permisos de cámara y ubicación
2. Acepta todos los permisos necesarios
3. Llegarás a la pantalla principal

### Navegación

1. **Selecciona un destino** de la lista:
   - Cocina
   - Sala de Estar
   - Dormitorio
   - Baño
   - Entrada

2. **Toca "Iniciar Navegación AR"**

3. **Apunta con la cámara** y sigue las indicaciones:
   - **Flecha azul**: Dirección del destino
   - **Marcador flotante**: Posición del destino en el espacio
   - **Distancia**: Metros hasta el destino
   - **Instrucciones**: Texto guiando tu movimiento

### Probando en Casa

Los waypoints están configurados con coordenadas relativas. Para probar:

1. **Posición inicial**: Párate en el centro de una habitación
2. **Selecciona un destino**: Por ejemplo "Cocina"
3. **Mueve el dispositivo**: La flecha y el marcador se actualizarán
4. **Camina hacia el destino**: Las indicaciones se ajustan en tiempo real

**Tip**: Los valores de distancia son relativos. Puedes editar las coordenadas en `lib/models/waypoint_data.dart` para ajustarlas a tu espacio real.

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada y manejo de permisos
├── models/
│   ├── waypoint.dart           # Modelo de punto de navegación
│   └── waypoint_data.dart      # Datos de ejemplo de waypoints
├── screens/
│   ├── home_screen.dart        # Pantalla de selección de destino
│   └── ar_view_screen.dart     # Vista AR con cámara y sensores
└── widgets/
    └── ar_overlay.dart         # Overlay AR con indicadores visuales
```

## 🎨 Personalización

### Agregar Nuevos Waypoints

Edita `lib/models/waypoint_data.dart`:

```dart
Waypoint(
  id: '6',
  name: 'Mi Oficina',
  description: 'Espacio de trabajo',
  latitude: 2.0,    // Coordenada X
  longitude: 4.0,   // Coordenada Y
  altitude: 0.0,    // Altura (piso)
  icon: Icons.work,
),
```

### Ajustar Coordenadas

Las coordenadas usan un sistema relativo:
- `latitude` y `longitude`: Posición en el plano horizontal
- `altitude`: Altura (útil para edificios multinivel)
- Unidades en metros aproximados

## 🔧 Configuración Técnica

### Permisos Android

Configurados en `android/app/src/main/AndroidManifest.xml`:
- `CAMERA`: Para la vista AR
- `ACCESS_FINE_LOCATION`: Para geolocalización
- `ACCESS_COARSE_LOCATION`: Backup de localización

### Permisos iOS

Configurados en `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`

## 📦 Dependencias Principales

- `camera`: Acceso a la cámara del dispositivo
- `sensors_plus`: Acelerómetro y magnetómetro
- `permission_handler`: Gestión de permisos
- `flutter_compass`: Brújula digital
- `geolocator`: Servicios de ubicación

## 🐛 Solución de Problemas

### La cámara no se inicia
- Verifica que otorgaste permisos de cámara
- Reinicia la aplicación
- Verifica que estés en un dispositivo físico (no emulador)

### Los sensores no responden
- Algunos dispositivos tienen sensores de baja calidad
- Calibra la brújula del dispositivo (mueve el teléfono en forma de 8)
- Aléjate de objetos metálicos que puedan interferir

### La navegación no es precisa
- Este es un sistema de demostración con coordenadas relativas
- Para mayor precisión, integra GPS real y mapas de interiores
- Ajusta las coordenadas en `waypoint_data.dart` según tu espacio

## 🚧 Trabajo Futuro

- [ ] Integración con GPS real para exteriores
- [ ] Mapas de interiores interactivos
- [ ] Persistencia de waypoints personalizados
- [ ] Rutas multi-punto
- [ ] Soporte para múltiples pisos
- [ ] Calibración automática de coordenadas
- [ ] Modo offline completo

## 📄 Licencia

Ver archivo [LICENSE](LICENSE)

## 👥 Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si tienes problemas o preguntas, abre un issue en el repositorio.

---

**Nota**: Esta es una aplicación de demostración para navegación AR básica. Para uso en producción, considera implementar sistemas de posicionamiento indoor más robustos como Bluetooth beacons, WiFi triangulation, o Visual Positioning Systems (VPS).