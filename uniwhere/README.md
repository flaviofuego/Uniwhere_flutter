# AR Home Navigator Demo

Demo de navegación interior que combina AR Wayfinding + VPS simulado para una casa. Diseñada como prototipo de un sistema escalable a campus universitario.

## Requisitos

- Flutter 3.9+ (canal stable)
- Dispositivo físico con cámara (los emuladores no soportan AR)
- Android SDK 24+ / iOS 14+

## Instalación

```bash
flutter pub get
flutter run
```

### Permisos

- **Android**: Cámara, ubicación aproximada/precisa y vibración ya declarados en `AndroidManifest.xml`.
- **iOS**: Cámara y ubicación en `Info.plist`.

## Uso

1. **Pantalla de inicio**: Entrar a modo Calibración, Navegación o ver Mapa 2D.
2. **Modo Calibración**: Usa el botón “Marcar punto actual” para registrar habitaciones, categorías y referencias de imagen (VPS).
3. **Modo Navegación**: Selecciona destino desde el buscador, observa flechas/línea de ruta, panel inferior con distancia y tiempo. Botón para simular match de VPS.
4. **Mapa 2D**: Vista cenital con puntos guardados, posición actual y ruta.
5. **Fichas AR**: Mantén presionado sobre la vista AR para abrir una tarjeta con información y botones “Navegar aquí / Cerrar”.

## Datos precargados

Se incluyen Sala, Cocina, Baño, Cuarto Principal y Estudio con coordenadas relativas al origen (0,0,0).

## Estructura

- `lib/models`: Modelos `RoomLocation`, `NavigationPath`, `ARInfoCard`.
- `lib/services`: Lógica de navegación, simulación VPS y bitácora.
- `lib/screens`: Home, Calibración, Navegación AR, Mapa 2D.
- `lib/widgets`: Overlays AR, panel de debug, mapa esquemático y fichas.
- `assets/`: Íconos, imágenes y modelos de ejemplo (placeholders).

## Troubleshooting

- Si no se detecta la cámara, revisa permisos del sistema.
- AR necesita buen nivel de luz para detección de planos.
- Usa un espacio de 5–20 m para pruebas; las posiciones son relativas al punto inicial.
