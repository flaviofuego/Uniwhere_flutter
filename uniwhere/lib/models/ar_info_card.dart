/// Modelo de ficha de información que se muestra al enfocar un punto de interés.
class ARInfoCard {
  /// Título principal de la ficha.
  final String title;

  /// Contenido descriptivo extendido.
  final String content;

  /// Imagen de referencia (puede ser de red o asset).
  final String imageUrl;

  /// Lista de características o atributos rápidos.
  final List<String> features;

  const ARInfoCard({
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.features,
  });
}
