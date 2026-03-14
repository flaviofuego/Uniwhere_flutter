import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/waypoint.dart';
import '../models/point_of_interest.dart';
import '../models/navigation_pose.dart';

/// Servicio de comunicación con el backend FastAPI.
/// Encapsula todas las llamadas HTTP al servidor de localización y navegación.
///
/// Endpoints disponibles:
///   POST /localize          → devuelve pose y nodo más cercano
///   GET  /route             → devuelve lista de waypoints entre dos nodos
///   GET  /points_of_interest → devuelve todos los nodos del mapa
class BackendService {
  /// URL base del servidor FastAPI (actualizable desde SettingsScreen)
  String baseUrl;

  /// Timeout para peticiones generales
  static const Duration _timeout = Duration(milliseconds: 5000);

  /// Timeout extendido para /localize (visión por computadora tarda más)
  static const Duration _localizeTimeout = Duration(milliseconds: 8000);

  BackendService({required this.baseUrl});

  // ============================================================================
  // COMPROBACIÓN DE CONEXIÓN
  // ============================================================================

  /// Verifica si el backend está disponible haciendo una petición ligera.
  /// Devuelve true si responde, false si hay error de red.
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/points_of_interest'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================================
  // GET /points_of_interest
  // ============================================================================

  /// Obtiene la lista completa de puntos de interés del campus.
  /// Lanza [BackendException] si hay error de red o respuesta inválida.
  Future<List<PointOfInterest>> getPointsOfInterest() async {
    final uri = Uri.parse('$baseUrl/points_of_interest');

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // El backend puede devolver una lista directa o un objeto con "pois"
        List<dynamic> rawList;
        if (data is List) {
          rawList = data;
        } else if (data is Map && data.containsKey('pois')) {
          rawList = data['pois'] as List<dynamic>;
        } else if (data is Map && data.containsKey('points')) {
          rawList = data['points'] as List<dynamic>;
        } else {
          throw BackendException('Formato de respuesta inesperado en /points_of_interest');
        }

        return rawList
            .map((e) => PointOfInterest.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw BackendException(
          'Error del servidor: ${response.statusCode} - ${response.body}',
        );
      }
    } on BackendException {
      rethrow;
    } catch (e) {
      // Error de red o timeout
      throw BackendException(_networkErrorMessage(e));
    }
  }

  // ============================================================================
  // GET /route?origin=X&destination=Y
  // ============================================================================

  /// Calcula la ruta entre dos nodos del grafo.
  /// [origin] y [destination] son IDs de nodos (nearest_node del /localize).
  /// Devuelve lista ordenada de [Waypoint] que forman el camino.
  Future<List<Waypoint>> getRoute({
    required String origin,
    required String destination,
  }) async {
    final uri = Uri.parse('$baseUrl/route').replace(
      queryParameters: {'origin': origin, 'destination': destination},
    );

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> rawList;
        if (data is List) {
          rawList = data;
        } else if (data is Map && data.containsKey('waypoints')) {
          rawList = data['waypoints'] as List<dynamic>;
        } else if (data is Map && data.containsKey('route')) {
          rawList = data['route'] as List<dynamic>;
        } else {
          throw BackendException('Formato de respuesta inesperado en /route');
        }

        return rawList
            .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        throw BackendException('No existe ruta entre "$origin" y "$destination"');
      } else {
        throw BackendException('Error del servidor: ${response.statusCode}');
      }
    } on BackendException {
      rethrow;
    } catch (e) {
      throw BackendException(_networkErrorMessage(e));
    }
  }

  // ============================================================================
  // POST /localize
  // ============================================================================

  /// Envía un frame de imagen al backend para localización visual.
  ///
  /// El backend compara el frame contra los descriptores SuperPoint extraídos
  /// de las imágenes originales de COLMAP (grabadas con smartphone).
  /// SuperGlue realiza el matching entre descriptores y hloc estima la pose
  /// dentro del modelo 3D reconstruido con COLMAP a partir de esos videos.
  ///
  /// [imageBytes] - imagen capturada desde la cámara AR, redimensionada a la
  ///               resolución de grabación de COLMAP (ver AppConfig.colmapCameraModel)
  /// [filename]   - nombre del archivo enviado en el multipart
  ///
  /// Devuelve [NavigationPose] con la posición en el mapa y el nodo más cercano.
  Future<NavigationPose> localize({
    required Uint8List imageBytes,
    String filename = 'frame.jpg',
  }) async {
    final uri = Uri.parse('$baseUrl/localize');

    try {
      // Crear petición multipart/form-data
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Nombre del campo que espera el backend FastAPI
          imageBytes,
          filename: filename,
        ),
      );

      // Enviar petición con timeout extendido
      final streamedResponse = await request.send().timeout(_localizeTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return NavigationPose.fromJson(data);
      } else if (response.statusCode == 422) {
        throw BackendException('Imagen no reconocida por el sistema de localización');
      } else {
        throw BackendException('Error de localización: ${response.statusCode}');
      }
    } on BackendException {
      rethrow;
    } catch (e) {
      throw BackendException(_networkErrorMessage(e));
    }
  }

  // ============================================================================
  // HELPER PRIVADO
  // ============================================================================

  /// Genera un mensaje de error amigable en español para errores de red
  String _networkErrorMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timedout')) {
      return 'El servidor tardó demasiado en responder. Verifica tu conexión WiFi.';
    }
    if (msg.contains('refused') || msg.contains('connection')) {
      return 'No se puede conectar al servidor. Verifica la IP y que el backend esté corriendo.';
    }
    if (msg.contains('socket')) {
      return 'Error de red. Verifica conexión WiFi al servidor.';
    }
    return 'Error de conexión: verifica la IP del backend en Configuración.';
  }
}

/// Excepción específica del servicio backend.
/// Contiene un mensaje en español listo para mostrar al usuario.
class BackendException implements Exception {
  final String message;
  const BackendException(this.message);

  @override
  String toString() => 'BackendException: $message';
}
