import 'package:permission_handler/permission_handler.dart';

/// Servicio para gestión de permisos de la aplicación
/// Maneja permisos de cámara requeridos para AR
class PermissionsService {
  /// Solicita permiso de cámara
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Verifica si el permiso de cámara está otorgado
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Solicita permiso de almacenamiento (para imágenes de referencia)
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
  }

  /// Verifica si el permiso de almacenamiento está otorgado
  Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted || status.isLimited;
  }

  /// Solicita todos los permisos necesarios
  Future<Map<String, bool>> requestAllPermissions() async {
    final camera = await requestCameraPermission();
    final storage = await requestStoragePermission();
    
    return {
      'camera': camera,
      'storage': storage,
    };
  }

  /// Verifica si todos los permisos necesarios están otorgados
  Future<bool> hasAllPermissions() async {
    final camera = await hasCameraPermission();
    final storage = await hasStoragePermission();
    
    return camera && storage;
  }

  /// Abre la configuración de la aplicación
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Muestra el estado de todos los permisos
  Future<Map<String, PermissionStatus>> getPermissionsStatus() async {
    return {
      'camera': await Permission.camera.status,
      'storage': await Permission.storage.status,
    };
  }
}
