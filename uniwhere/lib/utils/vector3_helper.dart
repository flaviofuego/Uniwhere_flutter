import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

/// Helper para operaciones matemáticas con Vector3
/// Incluye cálculos de dirección, rotación y manipulación vectorial
class Vector3Helper {
  /// Calcula el vector de dirección normalizado de A hacia B
  static Vector3 direction(Vector3 from, Vector3 to) {
    return (to - from).normalized();
  }

  /// Calcula el ángulo en radianes entre dos vectores
  static double angleBetween(Vector3 v1, Vector3 v2) {
    double dot = v1.normalized().dot(v2.normalized());
    // Clamp para evitar errores por precisión de punto flotante
    dot = dot.clamp(-1.0, 1.0);
    return math.acos(dot);
  }

  /// Calcula el ángulo en grados entre dos vectores
  static double angleBetweenDegrees(Vector3 v1, Vector3 v2) {
    return radians2Degrees(angleBetween(v1, v2));
  }

  /// Calcula el ángulo de rotación en el plano XZ (útil para brújula/navegación)
  /// Retorna ángulo en radianes desde el norte (eje -Z)
  static double horizontalAngle(Vector3 direction) {
    // Proyectar en plano XZ
    Vector2 horizontal = Vector2(direction.x, direction.z);
    // Vector norte es (0, -1) en el plano XZ
    Vector2 north = Vector2(0, -1);
    
    double angle = math.atan2(horizontal.y, horizontal.x) - math.atan2(north.y, north.x);
    
    // Normalizar entre 0 y 2π
    if (angle < 0) {
      angle += 2 * math.pi;
    }
    
    return angle;
  }

  /// Calcula el ángulo horizontal en grados
  static double horizontalAngleDegrees(Vector3 direction) {
    return radians2Degrees(horizontalAngle(direction));
  }

  /// Interpola linealmente entre dos vectores
  static Vector3 lerp(Vector3 start, Vector3 end, double t) {
    t = t.clamp(0.0, 1.0);
    return start + (end - start) * t;
  }

  /// Interpola de forma suave (smoothstep) entre dos vectores
  static Vector3 smoothLerp(Vector3 start, Vector3 end, double t) {
    t = t.clamp(0.0, 1.0);
    t = t * t * (3.0 - 2.0 * t); // Función smoothstep
    return lerp(start, end, t);
  }

  /// Proyecta un vector en un plano (elimina componente Y para proyección horizontal)
  static Vector3 projectOnPlane(Vector3 vector, Vector3 planeNormal) {
    double distance = vector.dot(planeNormal);
    return vector - planeNormal * distance;
  }

  /// Proyecta en plano horizontal (elimina componente Y)
  static Vector3 projectOnHorizontalPlane(Vector3 vector) {
    return Vector3(vector.x, 0, vector.z);
  }

  /// Rota un vector alrededor del eje Y (útil para rotación de brújula)
  static Vector3 rotateAroundY(Vector3 vector, double angleRadians) {
    double cos = math.cos(angleRadians);
    double sin = math.sin(angleRadians);
    
    return Vector3(
      vector.x * cos - vector.z * sin,
      vector.y,
      vector.x * sin + vector.z * cos,
    );
  }

  /// Calcula punto medio entre dos vectores
  static Vector3 midpoint(Vector3 v1, Vector3 v2) {
    return (v1 + v2) / 2.0;
  }

  /// Verifica si dos vectores son aproximadamente iguales (con epsilon)
  static bool approximatelyEqual(Vector3 v1, Vector3 v2, {double epsilon = 0.001}) {
    return (v1 - v2).length < epsilon;
  }

  /// Clampea la magnitud de un vector
  static Vector3 clampMagnitude(Vector3 vector, double maxLength) {
    double length = vector.length;
    if (length > maxLength) {
      return vector.normalized() * maxLength;
    }
    return vector;
  }

  /// Refleja un vector respecto a un plano definido por su normal
  static Vector3 reflect(Vector3 vector, Vector3 normal) {
    return vector - normal * (2.0 * vector.dot(normal));
  }

  /// Calcula la distancia más corta de un punto a una línea
  static double distanceToLine(Vector3 point, Vector3 lineStart, Vector3 lineEnd) {
    Vector3 lineDirection = (lineEnd - lineStart).normalized();
    Vector3 pointVector = point - lineStart;
    
    double projection = pointVector.dot(lineDirection);
    Vector3 closestPoint = lineStart + lineDirection * projection;
    
    return point.distanceTo(closestPoint);
  }

  /// Encuentra el punto más cercano en una línea
  static Vector3 closestPointOnLine(Vector3 point, Vector3 lineStart, Vector3 lineEnd) {
    Vector3 lineDirection = (lineEnd - lineStart).normalized();
    Vector3 pointVector = point - lineStart;
    
    double projection = pointVector.dot(lineDirection);
    double lineLength = lineStart.distanceTo(lineEnd);
    
    // Clampear entre inicio y fin de la línea
    projection = projection.clamp(0.0, lineLength);
    
    return lineStart + lineDirection * projection;
  }

  /// Crea un vector desde coordenadas esféricas (útil para AR)
  /// theta: ángulo azimutal (horizontal), phi: ángulo polar (vertical)
  static Vector3 fromSpherical(double radius, double theta, double phi) {
    return Vector3(
      radius * math.sin(phi) * math.cos(theta),
      radius * math.cos(phi),
      radius * math.sin(phi) * math.sin(theta),
    );
  }

  /// Convierte vector a coordenadas esféricas
  /// Retorna [radius, theta, phi]
  static List<double> toSpherical(Vector3 vector) {
    double radius = vector.length;
    double theta = math.atan2(vector.z, vector.x);
    double phi = math.acos(vector.y / radius);
    
    return [radius, theta, phi];
  }

  /// Calcula el vector perpendicular en el plano horizontal
  static Vector3 perpendicularHorizontal(Vector3 vector) {
    // Rotar 90 grados en el plano XZ
    return Vector3(-vector.z, vector.y, vector.x);
  }

  /// Suaviza el movimiento de un vector hacia un objetivo (damping)
  static Vector3 smoothDamp(
    Vector3 current,
    Vector3 target,
    Vector3 currentVelocity,
    double smoothTime,
    double deltaTime, {
    double maxSpeed = double.infinity,
  }) {
    smoothTime = math.max(0.0001, smoothTime);
    double omega = 2.0 / smoothTime;
    double x = omega * deltaTime;
    double exp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x);
    
    Vector3 change = current - target;
    Vector3 originalTo = target;
    
    double maxChange = maxSpeed * smoothTime;
    change = clampMagnitude(change, maxChange);
    target = current - change;
    
    Vector3 temp = (currentVelocity + change * omega) * deltaTime;
    currentVelocity = (currentVelocity - temp * omega) * exp;
    Vector3 output = target + (change + temp) * exp;
    
    if ((originalTo - current).dot(output - originalTo) > 0) {
      output = originalTo;
      currentVelocity = (output - originalTo) / deltaTime;
    }
    
    return output;
  }

  /// Convierte radianes a grados
  static double radians2Degrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Convierte grados a radianes
  static double degrees2Radians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Normaliza un ángulo entre 0 y 360 grados
  static double normalizeAngle(double angle) {
    while (angle < 0) {
      angle += 360;
    }
    while (angle >= 360) {
      angle -= 360;
    }
    return angle;
  }

  /// Calcula la diferencia más corta entre dos ángulos
  static double deltaAngle(double current, double target) {
    double delta = target - current;
    delta = (delta + 180) % 360 - 180;
    return delta;
  }
}
