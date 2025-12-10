# TODO: Mejoras Futuras para Producción

Este documento lista las mejoras necesarias para convertir este prototipo en una aplicación de producción.

## 🔴 Crítico (Requerido para Producción)

### 1. Integración AR Real
- [ ] Reemplazar `ARService` simulado con implementación real
- [ ] Usar `ar_flutter_plugin` para cross-platform
- [ ] Implementar detección real de planos horizontales
- [ ] Gestión de anclajes AR persistentes
- [ ] Manejo de pérdida/recuperación de tracking
- [ ] Calibración automática de escala

**Archivos a modificar:**
- `lib/services/ar_service.dart` - Reemplazar completamente

### 2. VPS Robusto
- [ ] Integrar Google ML Kit para matching de imágenes
- [ ] Usar ARCore Cloud Anchors para compartir ubicaciones
- [ ] Feature extraction con SIFT/ORB
- [ ] Confidence scoring mejorado
- [ ] Caching de imágenes procesadas

**Archivos a modificar:**
- `lib/services/vps_service.dart` - Añadir ML Kit

### 3. Generación de Adaptadores Hive
- [ ] Generar `room_location.g.dart` con build_runner
- [ ] Configurar serialización automática
- [ ] Migrations de base de datos

**Comandos:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🟡 Alta Prioridad (Importantes para UX)

### 4. Tutorial Interactivo
- [ ] Pantalla de onboarding en primera ejecución
- [ ] Tour guiado de features
- [ ] Tips contextuales
- [ ] Skip option

**Nueva pantalla:**
- `lib/screens/onboarding_screen.dart`

### 5. Persistencia de Estado
- [ ] Guardar última posición AR
- [ ] Recuperar navegación interrumpida
- [ ] Cache de rutas calculadas
- [ ] Estado de calibración

### 6. Indicadores AR 3D Reales
- [ ] Modelos 3D de flechas
- [ ] Renderizado en espacio AR
- [ ] Animaciones de rotación
- [ ] Scaling según distancia
- [ ] Oclusión básica

**Assets necesarios:**
- `assets/models/arrow.gltf`
- `assets/models/marker.gltf`

### 7. Accesibilidad
- [ ] Guía por voz (Text-to-Speech)
- [ ] Vibración direccional (si hardware lo soporta)
- [ ] Modo alto contraste
- [ ] Tamaños de fuente ajustables
- [ ] Screen reader compatibility

### 8. Networking y Backend
- [ ] API REST para sincronización
- [ ] Compartir mapas entre usuarios
- [ ] Base de datos centralizada (Firebase/Supabase)
- [ ] Autenticación de usuarios
- [ ] Analytics

**Nuevo servicio:**
- `lib/services/api_service.dart`
- `lib/services/auth_service.dart`

## 🟢 Media Prioridad (Nice to Have)

### 9. Mejoras de UI
- [ ] Tema oscuro
- [ ] Animaciones más fluidas
- [ ] Gestos avanzados (pinch-to-zoom en mapa)
- [ ] Customización de colores
- [ ] Modo compacto para pantallas pequeñas

### 10. Pathfinding Avanzado
- [ ] A* completo con detección de obstáculos
- [ ] Múltiples rutas alternativas
- [ ] Preferencias de ruta (escaleras vs elevador)
- [ ] Rutas accesibles
- [ ] Evitar áreas restringidas

**Archivo a extender:**
- `lib/utils/pathfinding_helper.dart`

### 11. Funciones Sociales
- [ ] Compartir ubicaciones con amigos
- [ ] Puntos de encuentro
- [ ] Check-in en ubicaciones
- [ ] Valoraciones y comentarios

### 12. Optimizaciones de Performance
- [ ] Profiling de rendimiento
- [ ] Lazy loading de ubicaciones
- [ ] Compresión de imágenes de referencia
- [ ] Background processing
- [ ] Battery optimization

### 13. Testing Exhaustivo
- [ ] Unit tests para todos los servicios
- [ ] Widget tests para pantallas
- [ ] Integration tests
- [ ] Tests de navegación
- [ ] Coverage > 80%

**Estructura de tests:**
```
test/
├── models/
├── services/
├── widgets/
└── screens/
```

## 🔵 Baja Prioridad (Futuro)

### 14. Features Avanzadas
- [ ] Realidad aumentada multiusuario
- [ ] Sharing de sesiones AR en tiempo real
- [ ] Indoor positioning sin VPS (WiFi triangulation)
- [ ] Integración con Google Maps Indoor
- [ ] Exportar/importar mapas

### 15. Monetización (Si aplica)
- [ ] Ads no intrusivos
- [ ] Versión Premium sin ads
- [ ] Mapas premium de instituciones

### 16. Localización
- [ ] Soporte multi-idioma (i18n)
- [ ] Traducción de ubicaciones
- [ ] Formatos de fecha/hora locales

**Archivos nuevos:**
- `lib/l10n/` - Traducciones
- `l10n.yaml` - Configuración

### 17. Analytics y Monitoring
- [ ] Crashlytics
- [ ] Performance monitoring
- [ ] User behavior analytics
- [ ] A/B testing

## 📝 Notas de Implementación

### Priorización Recomendada por Fase

**Fase 1 (MVP Real):**
1. Integración AR Real (#1)
2. VPS Robusto (#2)
3. Generación Hive (#3)
4. Tutorial (#4)

**Fase 2 (Mejoras UX):**
5. Persistencia (#5)
6. Indicadores 3D (#6)
7. Accesibilidad (#7)
8. Mejoras UI (#9)

**Fase 3 (Escalabilidad):**
9. Networking (#8)
10. Pathfinding avanzado (#10)
11. Optimizaciones (#12)
12. Testing (#13)

**Fase 4 (Campus Real):**
- Múltiples edificios
- Sincronización con horarios
- Escalabilidad masiva
- Features sociales (#11)

## 🚨 Problemas Conocidos a Resolver

### Bug #1: Sin tracking real
**Descripción:** AR es simulado, no funciona con hardware real.
**Solución:** Ver TODO #1

### Bug #2: Imágenes VPS no se procesan
**Descripción:** Solo se guarda la ruta, no hay matching real.
**Solución:** Ver TODO #2

### Bug #3: Coordenadas arbitrarias
**Descripción:** Sistema de coordenadas local no está calibrado con espacio real.
**Solución:** Implementar calibración automática de escala y orientación.

### Bug #4: Sin persistencia de origen
**Descripción:** El origen AR se pierde al cerrar la app.
**Solución:** Guardar origen en Hive y restaurar al abrir.

## 📊 Métricas de Éxito

Para considerar el proyecto production-ready:

- ✅ AR tracking funciona en >95% de condiciones de luz
- ✅ VPS reconoce ubicaciones con >85% de precisión
- ✅ Navegación llega al destino correcto en >98% de casos
- ✅ App no crash en 99.9% de sesiones
- ✅ Tiempo de inicio <3 segundos
- ✅ Uso de batería <5% por hora de navegación activa
- ✅ Coverage de tests >80%
- ✅ Rating en stores >4.5 estrellas

## 🔗 Referencias Útiles

### AR
- [ARCore Best Practices](https://developers.google.com/ar/develop/fundamentals)
- [ARKit Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/arkit)

### VPS
- [Google Cloud Anchors Guide](https://developers.google.com/ar/develop/cloud-anchors)
- [ML Kit Image Labeling](https://developers.google.com/ml-kit/vision/image-labeling)

### Flutter
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)

---

**Última actualización:** 2025-12-10
**Versión:** 1.0.0-demo
