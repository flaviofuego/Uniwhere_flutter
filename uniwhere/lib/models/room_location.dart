import 'package:vector_math/vector_math_64.dart';
import 'package:hive/hive.dart';

part 'room_location.g.dart';

/// Modelo que representa una ubicación/habitación en el espacio AR
/// Almacena información de posición, categoría y referencias para VPS
@HiveType(typeId: 0)
class RoomLocation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // Ej: "Cocina", "Sala", "Cuarto Principal"

  @HiveField(2)
  final String description; // Descripción breve de la ubicación

  @HiveField(3)
  final double posX; // Coordenada X en el sistema local

  @HiveField(4)
  final double posY; // Coordenada Y (altura, típicamente 1.5m)

  @HiveField(5)
  final double posZ; // Coordenada Z en el sistema local

  @HiveField(6)
  final String category; // "habitacion", "servicio", "recreacion", "trabajo"

  @HiveField(7)
  final String iconPath; // Ruta al ícono en assets

  @HiveField(8)
  final List<String> tags; // ["comida", "reuniones", etc.]

  @HiveField(9)
  final String? imageReference; // Ruta a imagen de referencia para VPS

  RoomLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.category,
    required this.iconPath,
    required this.tags,
    this.imageReference,
  });

  /// Obtiene la posición como Vector3 para cálculos 3D
  Vector3 get position => Vector3(posX, posY, posZ);

  /// Calcula la distancia euclidiana a otra ubicación
  double distanceTo(RoomLocation other) {
    return position.distanceTo(other.position);
  }

  /// Calcula la distancia desde un punto Vector3
  double distanceFromPoint(Vector3 point) {
    return position.distanceTo(point);
  }

  /// Obtiene el color asociado a la categoría
  String getCategoryColor() {
    switch (category) {
      case 'habitacion':
        return '#FF6B6B'; // Rojo suave
      case 'servicio':
        return '#4ECDC4'; // Verde azulado
      case 'recreacion':
        return '#45B7D1'; // Azul
      case 'trabajo':
        return '#FFA07A'; // Naranja suave
      default:
        return '#95A5A6'; // Gris
    }
  }

  /// Crea una copia con campos modificados
  RoomLocation copyWith({
    String? id,
    String? name,
    String? description,
    double? posX,
    double? posY,
    double? posZ,
    String? category,
    String? iconPath,
    List<String>? tags,
    String? imageReference,
  }) {
    return RoomLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      posZ: posZ ?? this.posZ,
      category: category ?? this.category,
      iconPath: iconPath ?? this.iconPath,
      tags: tags ?? this.tags,
      imageReference: imageReference ?? this.imageReference,
    );
  }

  /// Convierte a Map para serialización
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'posX': posX,
      'posY': posY,
      'posZ': posZ,
      'category': category,
      'iconPath': iconPath,
      'tags': tags,
      'imageReference': imageReference,
    };
  }

  /// Crea instancia desde Map
  factory RoomLocation.fromJson(Map<String, dynamic> json) {
    return RoomLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      posX: (json['posX'] as num).toDouble(),
      posY: (json['posY'] as num).toDouble(),
      posZ: (json['posZ'] as num).toDouble(),
      category: json['category'] as String,
      iconPath: json['iconPath'] as String,
      tags: List<String>.from(json['tags'] as List),
      imageReference: json['imageReference'] as String?,
    );
  }

  @override
  String toString() {
    return 'RoomLocation(id: $id, name: $name, position: ($posX, $posY, $posZ))';
  }
}
