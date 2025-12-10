import 'package:flutter/material.dart';

/// Constantes de la aplicación
/// Colores, tamaños, configuraciones y límites del sistema
class AppConstants {
  // ============================================================================
  // COLORES PRINCIPALES
  // ============================================================================
  
  /// Color principal de la app (Azul)
  static const Color primaryColor = Color(0xFF2196F3);
  
  /// Color secundario
  static const Color secondaryColor = Color(0xFF1976D2);
  
  /// Color de acento
  static const Color accentColor = Color(0xFF03A9F4);
  
  /// Color de fondo claro
  static const Color backgroundColor = Color(0xFFF5F5F5);
  
  /// Color de texto principal
  static const Color textPrimaryColor = Color(0xFF212121);
  
  /// Color de texto secundario
  static const Color textSecondaryColor = Color(0xFF757575);
  
  /// Color de éxito
  static const Color successColor = Color(0xFF4CAF50);
  
  /// Color de advertencia
  static const Color warningColor = Color(0xFFFFC107);
  
  /// Color de error
  static const Color errorColor = Color(0xFFF44336);

  // ============================================================================
  // COLORES DE NAVEGACIÓN (según distancia)
  // ============================================================================
  
  /// Color de flecha cuando está cerca del destino (<3m)
  static const Color arrowNearColor = Color(0xFF4CAF50); // Verde
  
  /// Color de flecha a distancia media (3-10m)
  static const Color arrowMediumColor = Color(0xFFFFC107); // Amarillo
  
  /// Color de flecha lejos del destino (>10m)
  static const Color arrowFarColor = Color(0xFFF44336); // Rojo
  
  /// Color de la línea de ruta en el piso
  static const Color pathLineColor = Color(0xFF2196F3);

  // ============================================================================
  // UMBRALES DE NAVEGACIÓN
  // ============================================================================
  
  /// Distancia mínima para considerar que llegó al destino (metros)
  static const double destinationThreshold = 1.0;
  
  /// Distancia para considerar cerca (metros)
  static const double nearThreshold = 3.0;
  
  /// Distancia para considerar distancia media (metros)
  static const double mediumThreshold = 10.0;
  
  /// Umbral para pasar al siguiente waypoint (metros)
  static const double waypointThreshold = 0.5;
  
  /// Velocidad de caminata promedio (m/s) para cálculo de tiempo
  static const double walkingSpeed = 1.4;

  // ============================================================================
  // CONFIGURACIÓN AR
  // ============================================================================
  
  /// Altura por defecto de objetos AR sobre el suelo (metros)
  static const double defaultARHeight = 1.5;
  
  /// Distancia máxima de renderizado de objetos AR (metros)
  static const double maxRenderDistance = 50.0;
  
  /// Tiempo de retención de focus para mostrar info card (segundos)
  static const int focusTimeForInfoCard = 2;
  
  /// Frame rate objetivo para modo navegación
  static const int navigationFrameRate = 30;
  
  /// Frame rate reducido para modo bajo consumo
  static const int lowPowerFrameRate = 15;

  // ============================================================================
  // CONFIGURACIÓN VPS
  // ============================================================================
  
  /// Umbral de similitud para reconocimiento de imagen (0.0 - 1.0)
  static const double vpsMatchThreshold = 0.70;
  
  /// Intervalo de verificación VPS (milisegundos)
  static const int vpsCheckInterval = 2000;

  // ============================================================================
  // LÍMITES Y RESTRICCIONES
  // ============================================================================
  
  /// Máximo número de ubicaciones que se pueden guardar
  static const int maxLocations = 20;
  
  /// Tamaño máximo de imagen de referencia (bytes) - 2MB
  static const int maxImageSize = 2 * 1024 * 1024;
  
  /// Longitud máxima del nombre de ubicación
  static const int maxLocationNameLength = 50;
  
  /// Longitud máxima de descripción
  static const int maxDescriptionLength = 200;

  // ============================================================================
  // CONFIGURACIÓN UI
  // ============================================================================
  
  /// Radio de borde de botones
  static const double buttonBorderRadius = 16.0;
  
  /// Radio de borde de tarjetas
  static const double cardBorderRadius = 12.0;
  
  /// Elevación de tarjetas
  static const double cardElevation = 4.0;
  
  /// Padding general
  static const double defaultPadding = 16.0;
  
  /// Espaciado entre elementos
  static const double defaultSpacing = 8.0;

  // ============================================================================
  // ANIMACIONES
  // ============================================================================
  
  /// Duración de animación estándar (milisegundos)
  static const int animationDuration = 300;
  
  /// Duración de animación rápida (milisegundos)
  static const int fastAnimationDuration = 150;
  
  /// Duración de animación lenta (milisegundos)
  static const int slowAnimationDuration = 500;

  // ============================================================================
  // KEYS DE ALMACENAMIENTO
  // ============================================================================
  
  /// Key para box de Hive de ubicaciones
  static const String locationsBoxKey = 'locations_box';
  
  /// Key para configuraciones
  static const String settingsBoxKey = 'settings_box';
  
  /// Key para imágenes de referencia
  static const String imagesBoxKey = 'reference_images_box';

  // ============================================================================
  // MENSAJES
  // ============================================================================
  
  /// Mensaje al llegar al destino
  static const String arrivedMessage = '¡Has llegado a tu destino!';
  
  /// Mensaje al actualizar posición VPS
  static const String vpsUpdateMessage = 'Posición actualizada';
  
  /// Mensaje al perder tracking
  static const String trackingLostMessage = 'Tracking perdido. Busca un punto de referencia.';
  
  /// Mensaje de calibración
  static const String calibrationMessage = 'Camina por la casa y marca puntos de interés';

  // ============================================================================
  // DEBUG
  // ============================================================================
  
  /// Activar modo debug por defecto
  static const bool debugModeDefault = true;
  
  /// Mostrar FPS en modo debug
  static const bool showFpsInDebug = true;
  
  /// Mostrar coordenadas en modo debug
  static const bool showCoordinatesInDebug = true;

  /// Obtiene el color de flecha según la distancia
  static Color getArrowColorByDistance(double distance) {
    if (distance < nearThreshold) {
      return arrowNearColor;
    } else if (distance < mediumThreshold) {
      return arrowMediumColor;
    } else {
      return arrowFarColor;
    }
  }

  /// Formatea distancia en formato legible
  static String formatDistance(double meters) {
    if (meters < 1.0) {
      return '${(meters * 100).toStringAsFixed(0)} cm';
    } else if (meters < 1000.0) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Formatea tiempo en formato legible
  static String formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    if (minutes < 60) {
      return '${minutes}m ${secs}s';
    }
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
