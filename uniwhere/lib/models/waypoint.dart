/// Modelo de un waypoint en la ruta de navegación.
/// Los waypoints son nodos del grafo del campus devueltos por el backend.
class Waypoint {
  /// Identificador único del nodo en el grafo
  final String id;

  /// Coordenada X en el mapa 3D (metros)
  final double x;

  /// Coordenada Y en el mapa 3D (metros, altura)
  final double y;

  /// Coordenada Z en el mapa 3D (metros)
  final double z;

  /// Etiqueta descriptiva opcional (ej: "Pasillo Norte", "Entrada Principal")
  final String? label;

  const Waypoint({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    this.label,
  });

  /// Crea un Waypoint desde un mapa JSON devuelto por el backend
  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id']?.toString() ?? json['node_id']?.toString() ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
      label: json['label']?.toString() ?? json['name']?.toString(),
    );
  }

  /// Convierte el waypoint a mapa JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'z': z,
        if (label != null) 'label': label,
      };

  /// Calcula la distancia euclídea 3D a otro waypoint
  double distanceTo(Waypoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return _sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Calcula la distancia plana (XZ) ignorando diferencias de altura
  double distancePlanarTo(Waypoint other) {
    final dx = x - other.x;
    final dz = z - other.z;
    return _sqrt(dx * dx + dz * dz);
  }

  /// Raíz cuadrada manual para evitar import de dart:math aquí
  double _sqrt(double value) {
    if (value <= 0) return 0;
    double result = value / 2;
    for (int i = 0; i < 20; i++) {
      result = (result + value / result) / 2;
    }
    return result;
  }

  @override
  String toString() => 'Waypoint(id: $id, x: $x, y: $y, z: $z, label: $label)';

  @override
  bool operator ==(Object other) =>
      other is Waypoint && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
