import 'package:flutter/foundation.dart';

import '../models/room_location.dart';
import 'navigation_service.dart';

/// Servicio que simula el posicionamiento visual (VPS).
/// No realiza matching real de imágenes, pero deja el flujo preparado
/// para conectar con Google ML Kit en una implementación futura.
class VpsService extends ChangeNotifier {
  VpsService(this._navigationService);

  final NavigationService _navigationService;

  /// Último punto que generó recalibración.
  RoomLocation? _lastMatch;

  RoomLocation? get lastMatch => _lastMatch;

  /// Simula el resultado de comparar la imagen actual con las referencias.
  /// Al encontrar coincidencia, solicita al NavigationService que se
  /// reposicione y emite un mensaje de confirmación.
  void simulateReferenceDetection(RoomLocation reference) {
    _lastMatch = reference;
    _navigationService.applyVpsMatch(reference);
    notifyListeners();
  }
}
