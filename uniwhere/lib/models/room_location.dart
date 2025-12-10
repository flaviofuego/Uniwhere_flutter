import 'package:vector_math/vector_math_64.dart';

/// Modelo que representa un punto de interés dentro de la casa.
/// Se usa para simular el sistema de coordenadas local y los datos
/// que luego podríamos persistir en Hive o SQLite.
class RoomLocation {
  /// Identificador único del punto.
  final String id;

  /// Nombre visible para el usuario, por ejemplo "Cocina".
  final String name;

  /// Descripción breve que aparecerá en las fichas AR.
  final String description;

  /// Posición relativa al origen (0,0,0) en metros.
  final Vector3 position;

  /// Categoría del espacio: "habitacion", "servicio", "recreacion", etc.
  final String category;

  /// Ruta de ícono representativo para mapas/overlays.
  final String iconPath;

  /// Lista de etiquetas para filtros rápidos.
  final List<String> tags;

  /// Nombre o identificador de la imagen usada por el VPS.
  final String? imageReference;

  const RoomLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.category,
    required this.iconPath,
    required this.tags,
    this.imageReference,
  });

  /// Facilita la creación de nuevas instancias manteniendo campos originales.
  RoomLocation copyWith({
    String? id,
    String? name,
    String? description,
    Vector3? position,
    String? category,
    String? iconPath,
    List<String>? tags,
    String? imageReference,
  }) {
    return RoomLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      position: position ?? this.position,
      category: category ?? this.category,
      iconPath: iconPath ?? this.iconPath,
      tags: tags ?? this.tags,
      imageReference: imageReference ?? this.imageReference,
    );
  }
}
