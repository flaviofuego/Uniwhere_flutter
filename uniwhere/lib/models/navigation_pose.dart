/// Modelo de la pose de navegación devuelta por POST /localize.
/// Representa la posición y orientación de la cámara en el mapa 3D del campus.
class NavigationPose {
  // ============================================================================
  // POSICIÓN EN EL MAPA (coordenadas del mapa 3D generado por RealSense)
  // ============================================================================

  /// Posición X en el mapa (metros)
  final double x;

  /// Posición Y en el mapa (metros, altura)
  final double y;

  /// Posición Z en el mapa (metros)
  final double z;

  // ============================================================================
  // ORIENTACIÓN - cuaternión (qx, qy, qz, qw)
  // ============================================================================

  final double qx;
  final double qy;
  final double qz;
  final double qw;

  // ============================================================================
  // INFORMACIÓN ADICIONAL DEL BACKEND
  // ============================================================================

  /// Nodo más cercano en el grafo de navegación (se usa como 'origin' en /route)
  final String nearestNode;

  /// Score de confianza de la localización (0.0 - 1.0)
  final double? confidence;

  /// Timestamp del backend (unix ms)
  final int? timestampMs;

  const NavigationPose({
    required this.x,
    required this.y,
    required this.z,
    required this.qx,
    required this.qy,
    required this.qz,
    required this.qw,
    required this.nearestNode,
    this.confidence,
    this.timestampMs,
  });

  /// Crea una pose desde el JSON devuelto por /localize
  factory NavigationPose.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver la pose dentro de un objeto "pose"
    final poseData = json['pose'] as Map<String, dynamic>? ?? json;

    return NavigationPose(
      x: (poseData['x'] as num?)?.toDouble() ?? 0.0,
      y: (poseData['y'] as num?)?.toDouble() ?? 0.0,
      z: (poseData['z'] as num?)?.toDouble() ?? 0.0,
      qx: (poseData['qx'] as num?)?.toDouble() ?? 0.0,
      qy: (poseData['qy'] as num?)?.toDouble() ?? 0.0,
      qz: (poseData['qz'] as num?)?.toDouble() ?? 0.0,
      qw: (poseData['qw'] as num?)?.toDouble() ?? 1.0,
      nearestNode: json['nearest_node']?.toString() ??
          poseData['nearest_node']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ??
          (poseData['confidence'] as num?)?.toDouble(),
      timestampMs: json['timestamp_ms'] as int?,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() => {
        'pose': {
          'x': x, 'y': y, 'z': z,
          'qx': qx, 'qy': qy, 'qz': qz, 'qw': qw,
        },
        'nearest_node': nearestNode,
        if (confidence != null) 'confidence': confidence,
        if (timestampMs != null) 'timestamp_ms': timestampMs,
      };

  /// Verifica si la localización es confiable (confidence > 0.5)
  bool get isReliable => confidence == null || confidence! > 0.5;

  /// Texto de posición para modo debug
  String get debugText =>
      'Pos: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})\n'
      'Rot: (${qx.toStringAsFixed(2)}, ${qy.toStringAsFixed(2)}, ${qz.toStringAsFixed(2)}, ${qw.toStringAsFixed(2)})\n'
      'Nodo: $nearestNode'
      '${confidence != null ? '\nConf: ${(confidence! * 100).toStringAsFixed(0)}%' : ''}';

  @override
  String toString() =>
      'NavigationPose(x: $x, y: $y, z: $z, node: $nearestNode, conf: $confidence)';
}
