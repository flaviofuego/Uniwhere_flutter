# Quick Start Guide - AR Home Navigator

Esta es una guía rápida para empezar a usar el proyecto en menos de 5 minutos.

## ⚡ Setup Rápido

### 1. Prerequisitos
```bash
# Verifica que tengas Flutter instalado
flutter --version

# Debe mostrar Flutter 3.9.2 o superior
```

### 2. Instalación
```bash
# Clona el repositorio
git clone https://github.com/flaviofuego/Uniwhere_flutter.git
cd Uniwhere_flutter/uniwhere

# Instala dependencias
flutter pub get

# Conecta tu dispositivo físico (AR no funciona en emuladores)
flutter devices
```

### 3. Ejecutar
```bash
# Android
flutter run

# iOS
cd ios && pod install && cd ..
flutter run
```

## 🎮 Primeros Pasos en la App

### Paso 1: Permisos
Cuando la app inicie, acepta:
- ✅ Permiso de cámara
- ✅ Permiso de almacenamiento

### Paso 2: Explorar Ubicaciones Pre-cargadas
La app viene con 5 ubicaciones de ejemplo:
- 🛋️ Sala (0, 0, 0)
- 🍳 Cocina (3, 0, -2)
- 🚿 Baño (-2, 0, 3)
- 🛏️ Cuarto Principal (4, 0, 4)
- 📚 Estudio (-3, 0, -3)

### Paso 3: Prueba la Navegación
1. En HomeScreen, toca cualquier ubicación
2. Toca "Navegar aquí"
3. Verás la pantalla AR con una flecha indicando dirección
4. La flecha cambia de color según la distancia

### Paso 4: Modo Calibración
1. Toca "Modo Calibración"
2. Presiona el botón "+" grande
3. Completa:
   - Nombre: "Mi Habitación"
   - Categoría: Habitación
   - Descripción: "Mi espacio personal"
4. (Opcional) Toma foto
5. Toca "Guardar"

### Paso 5: Ver Mapa 2D
1. Toca el ícono de mapa (arriba derecha)
2. Verás todas las ubicaciones en vista cenital
3. Tu posición actual está marcada en azul

## 🐛 Modo Debug

Activa información técnica:
1. En NavigationScreen o CalibrationScreen
2. Toca el ícono de bug (arriba derecha)
3. Verás panel con coordenadas, tracking, etc.

## 📱 Interfaces Principales

### HomeScreen
```
┌─────────────────────────┐
│  🔍 ¿A dónde quieres ir? │
├─────────────────────────┤
│ [Calibración] [Navegación]│
├─────────────────────────┤
│ 📍 Sala                  │
│ 📍 Cocina                │
│ 📍 Baño                  │
│ ...                      │
└─────────────────────────┘
      ⊕ Nueva Ubicación
```

### NavigationScreen
```
┌─────────────────────────┐
│ ← [🐛]          Estado:OK│
│                         │
│         ↑               │
│      (Flecha)           │
│       5.2m              │
│                         │
├─────────────────────────┤
│ Navegando a: Cocina     │
│ 📏 5.2m  ⏱️ 4s          │
└─────────────────────────┘
```

## 🔑 Shortcuts y Tips

### Búsqueda Rápida
En HomeScreen, escribe en la búsqueda:
- "cocina" → encuentra Cocina
- "descanso" → encuentra por tags
- "servicio" → filtra por categoría

### Gestos
- **Tap** en ubicación → Ver detalles
- **Tap** en "Navegar" → Iniciar navegación
- **Pull down** → Refresh lista
- **Swipe** bottom sheet → Ajustar altura

### Código de Colores
- 🟢 Verde: Cerca (<3m)
- 🟡 Amarillo: Medio (3-10m)
- 🔴 Rojo: Lejos (>10m)

## 🛠️ Solución Rápida de Problemas

### "Camera permission denied"
```bash
# Android: Configuración → Apps → AR Home Navigator → Permisos → Cámara
# iOS: Configuración → Privacidad → Cámara → AR Home Navigator
```

### "No hay ubicaciones"
La app debe cargar 5 ubicaciones automáticamente al iniciar. Si no aparecen:
```dart
// En main.dart, verifica que StorageService.initialize() se ejecute
```

### App no compila
```bash
flutter clean
flutter pub get
flutter run
```

### Emulador no funciona
⚠️ **AR requiere dispositivo físico.** Los emuladores no soportan:
- Cámara con movimiento
- Sensores AR (giroscopio, acelerómetro)
- Detección de planos

## 📚 Siguiente Nivel

### Para Entender el Código
1. Lee `PROJECT_SUMMARY.md` - Resumen completo
2. Lee `DEVELOPMENT.md` - Guía técnica
3. Explora `lib/services/` - Lógica principal

### Para Contribuir
1. Lee `TODO.md` - Qué falta por hacer
2. Fork el repo
3. Crea branch: `git checkout -b feature/mi-feature`
4. Commit: `git commit -m 'Add mi feature'`
5. Push: `git push origin feature/mi-feature`
6. Abre Pull Request

### Para Producción
Prioridades en orden:
1. ✅ Generar adaptadores Hive: `flutter pub run build_runner build`
2. ✅ Integrar AR real (reemplazar ARService simulado)
3. ✅ Añadir iconos reales en `assets/icons/`
4. ✅ Integrar VPS con ML Kit
5. ✅ Testing automatizado

Ver `TODO.md` para lista completa.

## 🎯 Objetivos de Testing

### Test Manual Básico (10 min)
- [ ] App inicia sin crash
- [ ] Permisos se solicitan correctamente
- [ ] 5 ubicaciones aparecen en HomeScreen
- [ ] Búsqueda funciona
- [ ] Navegación inicia al seleccionar destino
- [ ] Mapa 2D muestra ubicaciones
- [ ] Calibración permite añadir nueva ubicación
- [ ] Debug panel muestra información

### Test Completo (30 min)
- [ ] Todo lo anterior +
- [ ] Formulario de nueva ubicación valida inputs
- [ ] Foto se puede capturar (simulado)
- [ ] Panel de navegación muestra distancia correcta
- [ ] Código de color funciona (verde/amarillo/rojo)
- [ ] Mapa 2D dibuja ruta cuando está navegando
- [ ] Debug panel se puede toggle on/off
- [ ] Búsqueda filtra por nombre, descripción y tags

## 📞 Ayuda

### Documentación
- `README.md` - Guía completa de usuario
- `DEVELOPMENT.md` - Guía para desarrolladores
- `TODO.md` - Roadmap y mejoras futuras
- `PROJECT_SUMMARY.md` - Resumen ejecutivo

### Soporte
- GitHub Issues: Para reportar bugs
- GitHub Discussions: Para preguntas
- Pull Requests: Para contribuciones

## ⏱️ Timeline Esperado

- **5 min** - Setup e instalación
- **2 min** - Primera ejecución y exploración
- **5 min** - Probar navegación con datos de ejemplo
- **3 min** - Añadir nueva ubicación en calibración
- **2 min** - Explorar mapa 2D
- **3 min** - Activar debug y entender coordenadas

**Total: ~20 minutos** para entender completamente la app.

---

¡Listo! Ahora tienes todo lo necesario para empezar. 🚀

**Pro Tip:** Empieza con los datos de ejemplo antes de crear tus propias ubicaciones.
