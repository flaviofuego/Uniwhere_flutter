import 'package:uuid/uuid.dart';
import 'room_location.dart';

/// Datos precargados de ejemplo para demostración
/// Representa una casa típica con 5 ubicaciones principales
class SampleData {
  static const uuid = Uuid();

  /// Lista de ubicaciones de ejemplo para una casa
  static List<RoomLocation> getSampleLocations() {
    return [
      // Punto de origen - Sala
      RoomLocation(
        id: uuid.v4(),
        name: 'Sala',
        description: 'Área principal de estar y recepción. Espacio amplio para reuniones familiares.',
        posX: 0.0,
        posY: 1.5,
        posZ: 0.0,
        category: 'recreacion',
        iconPath: 'assets/icons/living_room.png',
        tags: ['reuniones', 'tv', 'sofá', 'familiar'],
        imageReference: null,
      ),

      // Cocina - 3 metros al este, 2 metros al norte
      RoomLocation(
        id: uuid.v4(),
        name: 'Cocina',
        description: 'Área de preparación de alimentos. Completamente equipada con electrodomésticos modernos.',
        posX: 3.0,
        posY: 1.5,
        posZ: -2.0,
        category: 'servicio',
        iconPath: 'assets/icons/kitchen.png',
        tags: ['comida', 'cocinar', 'refrigerador', 'estufa'],
        imageReference: null,
      ),

      // Baño - 2 metros al oeste, 3 metros al sur
      RoomLocation(
        id: uuid.v4(),
        name: 'Baño',
        description: 'Baño completo con ducha. Ventilación natural y bien iluminado.',
        posX: -2.0,
        posY: 1.5,
        posZ: 3.0,
        category: 'servicio',
        iconPath: 'assets/icons/bathroom.png',
        tags: ['higiene', 'ducha', 'inodoro', 'lavabo'],
        imageReference: null,
      ),

      // Cuarto Principal - 4 metros al este, 4 metros al sur
      RoomLocation(
        id: uuid.v4(),
        name: 'Cuarto Principal',
        description: 'Dormitorio principal con espacio amplio. Incluye closet y ventana grande.',
        posX: 4.0,
        posY: 1.5,
        posZ: 4.0,
        category: 'habitacion',
        iconPath: 'assets/icons/bedroom.png',
        tags: ['dormir', 'descanso', 'cama', 'closet', 'privado'],
        imageReference: null,
      ),

      // Estudio - 3 metros al oeste, 3 metros al norte
      RoomLocation(
        id: uuid.v4(),
        name: 'Estudio',
        description: 'Espacio de trabajo tranquilo. Ideal para lectura, estudio o trabajo remoto.',
        posX: -3.0,
        posY: 1.5,
        posZ: -3.0,
        category: 'trabajo',
        iconPath: 'assets/icons/study.png',
        tags: ['trabajo', 'lectura', 'escritorio', 'silencioso', 'concentración'],
        imageReference: null,
      ),
    ];
  }

  /// Obtiene descripciones de categorías
  static Map<String, String> getCategoryDescriptions() {
    return {
      'habitacion': 'Espacios para descanso y privacidad',
      'servicio': 'Áreas de funciones básicas del hogar',
      'recreacion': 'Zonas de entretenimiento y convivencia',
      'trabajo': 'Espacios para actividades productivas',
    };
  }

  /// Obtiene rutas de íconos por categoría
  static Map<String, String> getCategoryIcons() {
    return {
      'habitacion': 'assets/icons/bedroom.png',
      'servicio': 'assets/icons/service.png',
      'recreacion': 'assets/icons/recreation.png',
      'trabajo': 'assets/icons/work.png',
    };
  }

  /// Lista de categorías disponibles
  static List<String> getCategories() {
    return ['habitacion', 'servicio', 'recreacion', 'trabajo'];
  }

  /// Obtiene ubicación por nombre (para búsqueda rápida)
  static RoomLocation? getLocationByName(String name) {
    try {
      return getSampleLocations().firstWhere(
        (location) => location.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene ubicaciones por categoría
  static List<RoomLocation> getLocationsByCategory(String category) {
    return getSampleLocations()
        .where((location) => location.category == category)
        .toList();
  }

  /// Genera un ID único para nuevas ubicaciones
  static String generateId() {
    return uuid.v4();
  }
}
