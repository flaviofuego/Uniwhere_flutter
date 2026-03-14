import 'package:flutter/material.dart';

/// Configuración y constantes globales de UNIwhere
/// Colores, URLs, timeouts y parámetros del sistema
class AppConfig {
  // ============================================================================
  // COLORES UNIVERSITARIOS - Material Design 3
  // ============================================================================

  /// Azul universitario principal
  static const Color primaryColor = Color(0xFF003087);

  /// Variante más clara del azul universitario
  static const Color primaryVariant = Color(0xFF1A4BAB);

  /// Color de superficie/fondo
  static const Color surfaceColor = Color(0xFFF8F9FF);

  /// Blanco puro para texto sobre fondos oscuros
  static const Color onPrimaryColor = Colors.white;

  /// Color de éxito (verde)
  static const Color successColor = Color(0xFF2E7D32);

  /// Color de advertencia (ámbar)
  static const Color warningColor = Color(0xFFF57F17);

  /// Color de error (rojo)
  static const Color errorColor = Color(0xFFB71C1C);

  /// Color para flecha AR cerca del destino (<3 m)
  static const Color arrowNearColor = Color(0xFF2E7D32);

  /// Color para flecha AR a distancia media (3-10 m)
  static const Color arrowMedColor = Color(0xFFF9A825);

  /// Color para flecha AR lejos del destino (>10 m)
  static const Color arrowFarColor = Color(0xFFE53935);

  // ============================================================================
  // BACKEND FASTAPI
  // ============================================================================

  /// URL base por defecto del backend (puede cambiarse en SettingsScreen)
  static const String defaultBaseUrl = 'http://localhost:8000';

  /// Endpoint de localización visual (recibe imagen JPEG, devuelve pose)
  static const String localizeEndpoint = '/localize';

  /// Endpoint de ruta entre dos nodos del grafo
  static const String routeEndpoint = '/route';

  /// Endpoint de puntos de interés del mapa
  static const String poisEndpoint = '/points_of_interest';

  /// Timeout para llamadas HTTP (milisegundos)
  static const int httpTimeoutMs = 5000;

  /// Timeout extendido para /localize (el backend puede tardar más)
  static const int localizeTimeoutMs = 8000;

  // ============================================================================
  // COLMAP - Reconstrucción 3D del campus
  // ============================================================================

  /// Modelo de cámara usado al reconstruir el mapa con COLMAP.
  /// El mapa fue generado a partir de videos grabados con un smartphone normal.
  ///
  /// IMPORTANTE: las imágenes enviadas al backend para localización deben
  /// tener la misma resolución y FOV del smartphone usado para grabar los
  /// videos de COLMAP, de lo contrario los descriptores SuperPoint no
  /// coincidirán correctamente y la localización fallará.
  static const String colmapCameraModel = 'SIMPLE_RADIAL';

  // ============================================================================
  // NAVEGACIÓN AR
  // ============================================================================

  /// Intervalo de captura de frames para localización (milisegundos)
  static const int localizationIntervalMs = 2000;

  /// Distancia para considerar que el usuario llegó a un waypoint (metros)
  static const double waypointReachedThreshold = 1.5;

  /// Distancia para considerar que llegó al destino final (metros)
  static const double destinationReachedThreshold = 2.0;

  /// Velocidad de caminata promedio para estimar tiempo (m/s)
  static const double walkingSpeedMs = 1.4;

  // ============================================================================
  // UI / DIMENSIONES
  // ============================================================================

  /// Radio de borde estándar para cards y botones
  static const double borderRadius = 16.0;

  /// Padding horizontal general
  static const double horizontalPadding = 20.0;

  /// Elevación estándar de cards
  static const double cardElevation = 3.0;

  // ============================================================================
  // TEXTOS DE LA APP
  // ============================================================================

  /// Nombre de la aplicación
  static const String appName = 'UNIwhere';

  /// Nombre completo / slogan
  static const String appTagline = 'Navegación indoor universitaria';

  /// Versión de la app
  static const String appVersion = '1.0.0';

  /// Nombre de la institución (personalizable)
  static const String universityName = 'Universidad Nacional';

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Formatea una distancia en metros a texto legible en español
  static String formatDistance(double meters) {
    if (meters < 1.0) {
      return '${(meters * 100).toStringAsFixed(0)} cm';
    } else if (meters < 1000.0) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Estima el tiempo de caminata en segundos y devuelve texto legible
  static String formatWalkTime(double meters) {
    final seconds = (meters / walkingSpeedMs).round();
    if (seconds < 60) return '~${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '~${minutes}m ${secs}s';
  }

  /// Devuelve el color de la flecha según la distancia al destino
  static Color arrowColorByDistance(double distance) {
    if (distance < 3.0) return arrowNearColor;
    if (distance < 10.0) return arrowMedColor;
    return arrowFarColor;
  }
}
