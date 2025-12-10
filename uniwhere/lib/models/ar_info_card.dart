/// Modelo que representa una ficha de información que aparece en AR
/// al apuntar a un punto de interés
class ARInfoCard {
  /// Título principal de la ficha
  final String title;

  /// Contenido descriptivo
  final String content;

  /// URL o ruta de la imagen asociada
  final String imageUrl;

  /// Lista de características o datos relevantes
  /// Ejemplo: ["Capacidad: 4 personas", "Horario: 24/7", "WiFi disponible"]
  final List<String> features;

  /// ID de la ubicación asociada (para navegación)
  final String? locationId;

  ARInfoCard({
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.features,
    this.locationId,
  });

  /// Crea una ficha de información desde un RoomLocation
  factory ARInfoCard.fromRoomLocation(dynamic roomLocation) {
    // Features basadas en la categoría y tags
    List<String> features = [];
    
    if (roomLocation.category == 'servicio') {
      features.add('Servicio disponible');
    } else if (roomLocation.category == 'recreacion') {
      features.add('Área de descanso');
    } else if (roomLocation.category == 'trabajo') {
      features.add('Espacio de trabajo');
    }

    // Agregar tags como features
    for (var tag in roomLocation.tags) {
      features.add('• $tag');
    }

    return ARInfoCard(
      title: roomLocation.name,
      content: roomLocation.description,
      imageUrl: roomLocation.iconPath,
      features: features,
      locationId: roomLocation.id,
    );
  }

  /// Crea copia con campos modificados
  ARInfoCard copyWith({
    String? title,
    String? content,
    String? imageUrl,
    List<String>? features,
    String? locationId,
  }) {
    return ARInfoCard(
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      features: features ?? this.features,
      locationId: locationId ?? this.locationId,
    );
  }

  /// Convierte a Map para serialización
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'features': features,
      'locationId': locationId,
    };
  }

  /// Crea instancia desde Map
  factory ARInfoCard.fromJson(Map<String, dynamic> json) {
    return ARInfoCard(
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String,
      features: List<String>.from(json['features'] as List),
      locationId: json['locationId'] as String?,
    );
  }

  @override
  String toString() {
    return 'ARInfoCard(title: $title, features: ${features.length})';
  }
}
