import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/// Provider de configuración de la aplicación.
/// Persiste ajustes usando SharedPreferences:
///   - IP/URL del backend
///   - Modo debug (muestra coordenadas en pantalla)
class SettingsProvider extends ChangeNotifier {
  // ============================================================================
  // KEYS DE PERSISTENCIA
  // ============================================================================
  static const String _keyBaseUrl = 'backend_base_url';
  static const String _keyDebugMode = 'debug_mode';

  // ============================================================================
  // ESTADO
  // ============================================================================

  /// URL base del backend (ej: "http://192.168.1.10:8000")
  String _baseUrl = AppConfig.defaultBaseUrl;

  /// Modo debug: muestra coordenadas de pose en la pantalla AR
  bool _debugMode = false;

  /// ¿Ya se cargaron las preferencias de disco?
  bool _loaded = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  String get baseUrl => _baseUrl;
  bool get debugMode => _debugMode;
  bool get loaded => _loaded;

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================

  /// Carga las preferencias guardadas desde SharedPreferences.
  /// Llamar en el main antes de runApp o en un FutureBuilder.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? AppConfig.defaultBaseUrl;
    _debugMode = prefs.getBool(_keyDebugMode) ?? false;
    _loaded = true;
    notifyListeners();
  }

  // ============================================================================
  // SETTERS CON PERSISTENCIA
  // ============================================================================

  /// Actualiza la URL del backend y la guarda en disco
  Future<void> setBaseUrl(String url) async {
    // Normalizar: eliminar barra final
    _baseUrl = url.trim().endsWith('/')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
  }

  /// Activa o desactiva el modo debug y guarda en disco
  Future<void> setDebugMode(bool value) async {
    _debugMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDebugMode, value);
  }

  /// Restaura todos los ajustes a valores por defecto
  Future<void> resetToDefaults() async {
    _baseUrl = AppConfig.defaultBaseUrl;
    _debugMode = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyDebugMode);
  }
}
