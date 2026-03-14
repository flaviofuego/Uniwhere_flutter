/// Modelo de un Punto de Interés (POI) del campus universitario.
/// Se obtiene del endpoint GET /points_of_interest del backend.
class PointOfInterest {
  /// Identificador único del nodo en el grafo de navegación
  final String id;

  /// Nombre legible del lugar (ej: "Biblioteca Central", "Aula 301")
  final String name;

  /// Descripción opcional del lugar
  final String? description;

  /// Coordenada X en el mapa 3D (metros)
  final double x;

  /// Coordenada Y en el mapa 3D (metros, altura)
  final double y;

  /// Coordenada Z en el mapa 3D (metros)
  final double z;

  /// Edificio al que pertenece (opcional)
  final String? building;

  /// Piso en el que se encuentra (opcional)
  final int? floor;

  /// Categoría del lugar (ej: "aula", "servicios", "administración")
  final String? category;

  const PointOfInterest({
    required this.id,
    required this.name,
    this.description,
    required this.x,
    required this.y,
    required this.z,
    this.building,
    this.floor,
    this.category,
  });

  /// Crea un POI desde el JSON del backend.
  /// El backend puede devolver distintos formatos; manejamos ambos.
  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id']?.toString() ?? json['node_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['label']?.toString() ?? 'Sin nombre',
      description: json['description']?.toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
      building: json['building']?.toString(),
      floor: json['floor'] is int ? json['floor'] as int : null,
      category: json['category']?.toString(),
    );
  }

  /// Convierte el POI a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'x': x,
        'y': y,
        'z': z,
        if (building != null) 'building': building,
        if (floor != null) 'floor': floor,
        if (category != null) 'category': category,
      };

  /// Texto de subtítulo para mostrar en la UI
  String get subtitle {
    final parts = <String>[];
    if (building != null) parts.add(building!);
    if (floor != null) parts.add('Piso $floor');
    if (category != null) parts.add(category!);
    return parts.isNotEmpty ? parts.join(' · ') : 'Campus';
  }

  /// Icono recomendado según la categoría
  String get categoryIcon {
    switch (category?.toLowerCase()) {
      case 'biblioteca':
        return '📚';
      case 'aula':
      case 'salon':
        return '🎓';
      case 'laboratorio':
        return '🔬';
      case 'cafeteria':
      case 'comedor':
        return '🍽️';
      case 'administracion':
      case 'administración':
        return '🏛️';
      case 'bano':
      case 'baño':
        return '🚻';
      case 'entrada':
        return '🚪';
      default:
        return '📍';
    }
  }

  @override
  String toString() => 'PointOfInterest(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      other is PointOfInterest && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
