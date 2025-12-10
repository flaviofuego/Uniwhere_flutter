import 'package:hive_flutter/hive_flutter.dart';
import '../models/room_location.dart';
import '../models/sample_data.dart';
import '../utils/constants.dart';
import 'dart:io';

/// Servicio de almacenamiento local usando Hive
/// Gestiona persistencia de ubicaciones e imágenes de referencia
class StorageService {
  Box<RoomLocation>? _locationsBox;
  Box<String>? _imagesBox;
  Box? _settingsBox;

  /// Inicializa Hive y abre las boxes necesarias
  /// NOTA: Hive.initFlutter() y registerAdapter() deben llamarse en main.dart
  Future<void> initialize() async {
    try {
      // Abrir boxes (el adaptador ya debe estar registrado en main.dart)
      _locationsBox = await Hive.openBox<RoomLocation>(AppConstants.locationsBoxKey);
      _imagesBox = await Hive.openBox<String>(AppConstants.imagesBoxKey);
      _settingsBox = await Hive.openBox(AppConstants.settingsBoxKey);
      
      // Cargar datos de ejemplo si es la primera vez
      if (_locationsBox!.isEmpty) {
        await loadSampleData();
      }
    } catch (e) {
      // Si hay error, intentar borrar datos corruptos y reiniciar
      try {
        await Hive.deleteBoxFromDisk(AppConstants.locationsBoxKey);
        await Hive.deleteBoxFromDisk(AppConstants.imagesBoxKey);
        await Hive.deleteBoxFromDisk(AppConstants.settingsBoxKey);
        
        // Reintentar abrir las boxes
        _locationsBox = await Hive.openBox<RoomLocation>(AppConstants.locationsBoxKey);
        _imagesBox = await Hive.openBox<String>(AppConstants.imagesBoxKey);
        _settingsBox = await Hive.openBox(AppConstants.settingsBoxKey);
        
        await loadSampleData();
      } catch (e2) {
        // Fallback final
        rethrow;
      }
    }
  }

  /// Carga datos de ejemplo en la base de datos
  Future<void> loadSampleData() async {
    if (_locationsBox == null) return;
    
    final sampleLocations = SampleData.getSampleLocations();
    for (var location in sampleLocations) {
      await _locationsBox!.put(location.id, location);
    }
  }

  // ==========================================================================
  // UBICACIONES
  // ==========================================================================

  /// Guarda una nueva ubicación
  Future<void> saveLocation(RoomLocation location) async {
    if (_locationsBox == null) throw Exception('Storage not initialized');
    
    // Verificar límite de ubicaciones
    if (_locationsBox!.length >= AppConstants.maxLocations &&
        !_locationsBox!.containsKey(location.id)) {
      throw Exception('Límite máximo de ${AppConstants.maxLocations} ubicaciones alcanzado');
    }
    
    await _locationsBox!.put(location.id, location);
  }

  /// Obtiene todas las ubicaciones guardadas
  List<RoomLocation> getAllLocations() {
    if (_locationsBox == null) return [];
    return _locationsBox!.values.toList();
  }

  /// Obtiene una ubicación por ID
  RoomLocation? getLocation(String id) {
    if (_locationsBox == null) return null;
    return _locationsBox!.get(id);
  }

  /// Actualiza una ubicación existente
  Future<void> updateLocation(RoomLocation location) async {
    if (_locationsBox == null) throw Exception('Storage not initialized');
    await _locationsBox!.put(location.id, location);
  }

  /// Elimina una ubicación
  Future<void> deleteLocation(String id) async {
    if (_locationsBox == null) throw Exception('Storage not initialized');
    await _locationsBox!.delete(id);
    
    // También eliminar imagen de referencia asociada si existe
    await deleteReferenceImage(id);
  }

  /// Obtiene ubicaciones por categoría
  List<RoomLocation> getLocationsByCategory(String category) {
    return getAllLocations()
        .where((location) => location.category == category)
        .toList();
  }

  /// Busca ubicaciones por nombre
  List<RoomLocation> searchLocationsByName(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllLocations()
        .where((location) => 
          location.name.toLowerCase().contains(lowerQuery) ||
          location.description.toLowerCase().contains(lowerQuery)
        )
        .toList();
  }

  /// Busca ubicaciones por tags
  List<RoomLocation> searchLocationsByTags(List<String> tags) {
    return getAllLocations()
        .where((location) => 
          location.tags.any((tag) => tags.contains(tag.toLowerCase()))
        )
        .toList();
  }

  // ==========================================================================
  // IMÁGENES DE REFERENCIA
  // ==========================================================================

  /// Guarda una imagen de referencia para VPS
  Future<void> saveReferenceImage(String locationId, String imagePath) async {
    if (_imagesBox == null) throw Exception('Storage not initialized');
    await _imagesBox!.put(locationId, imagePath);
  }

  /// Obtiene la ruta de imagen de referencia de una ubicación
  String? getReferenceImage(String locationId) {
    if (_imagesBox == null) return null;
    return _imagesBox!.get(locationId);
  }

  /// Elimina imagen de referencia
  Future<void> deleteReferenceImage(String locationId) async {
    if (_imagesBox == null) return;
    
    // Obtener ruta y eliminar archivo
    final imagePath = _imagesBox!.get(locationId);
    if (imagePath != null) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Error al eliminar archivo, continuar
      }
      
      await _imagesBox!.delete(locationId);
    }
  }

  /// Obtiene todas las imágenes de referencia
  Map<String, String> getAllReferenceImages() {
    if (_imagesBox == null) return {};
    return Map<String, String>.from(_imagesBox!.toMap());
  }

  // ==========================================================================
  // CONFIGURACIONES
  // ==========================================================================

  /// Guarda una configuración
  Future<void> saveSetting(String key, dynamic value) async {
    if (_settingsBox == null) throw Exception('Storage not initialized');
    await _settingsBox!.put(key, value);
  }

  /// Obtiene una configuración
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (_settingsBox == null) return defaultValue;
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  /// Elimina una configuración
  Future<void> deleteSetting(String key) async {
    if (_settingsBox == null) return;
    await _settingsBox!.delete(key);
  }

  /// Obtiene modo debug
  bool getDebugMode() {
    return getSetting<bool>('debug_mode', defaultValue: AppConstants.debugModeDefault) ?? false;
  }

  /// Establece modo debug
  Future<void> setDebugMode(bool enabled) async {
    await saveSetting('debug_mode', enabled);
  }

  // ==========================================================================
  // UTILIDADES
  // ==========================================================================

  /// Elimina todos los datos
  Future<void> clearAllData() async {
    await _locationsBox?.clear();
    await _imagesBox?.clear();
    await _settingsBox?.clear();
    
    // Recargar datos de ejemplo
    await loadSampleData();
  }

  /// Cierra todas las boxes
  Future<void> close() async {
    await _locationsBox?.close();
    await _imagesBox?.close();
    await _settingsBox?.close();
  }

  /// Obtiene estadísticas de almacenamiento
  Map<String, dynamic> getStorageStats() {
    return {
      'total_locations': _locationsBox?.length ?? 0,
      'total_images': _imagesBox?.length ?? 0,
      'max_locations': AppConstants.maxLocations,
      'locations_by_category': {
        'habitacion': getLocationsByCategory('habitacion').length,
        'servicio': getLocationsByCategory('servicio').length,
        'recreacion': getLocationsByCategory('recreacion').length,
        'trabajo': getLocationsByCategory('trabajo').length,
      }
    };
  }

  /// Exporta todas las ubicaciones a JSON
  List<Map<String, dynamic>> exportLocations() {
    return getAllLocations()
        .map((location) => location.toJson())
        .toList();
  }

  /// Importa ubicaciones desde JSON
  Future<void> importLocations(List<Map<String, dynamic>> jsonList) async {
    for (var json in jsonList) {
      try {
        final location = RoomLocation.fromJson(json);
        await saveLocation(location);
      } catch (e) {
        // Continuar con siguiente ubicación si falla una
        continue;
      }
    }
  }
}
