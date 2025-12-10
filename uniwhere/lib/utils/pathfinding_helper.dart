import 'package:vector_math/vector_math_64.dart';
import 'dart:collection';
import 'dart:math' as math;

/// Helper para cálculo de rutas usando algoritmo A* simplificado
/// En esta demo, usamos línea directa, pero está preparado para expansión
class PathfindingHelper {
  /// Calcula una ruta simple en línea recta entre dos puntos
  /// Retorna lista de waypoints intermedios
  static List<Vector3> calculateDirectPath(
    Vector3 start,
    Vector3 end, {
    double waypointSpacing = 2.0, // Espaciado entre waypoints en metros
  }) {
    List<Vector3> waypoints = [start];
    
    double distance = start.distanceTo(end);
    int numWaypoints = (distance / waypointSpacing).ceil();
    
    // Crear waypoints intermedios espaciados uniformemente
    for (int i = 1; i < numWaypoints; i++) {
      double t = i / numWaypoints;
      Vector3 waypoint = Vector3(
        start.x + (end.x - start.x) * t,
        start.y + (end.y - start.y) * t,
        start.z + (end.z - start.z) * t,
      );
      waypoints.add(waypoint);
    }
    
    waypoints.add(end);
    return waypoints;
  }

  /// Calcula ruta con waypoints suavizados (curva Catmull-Rom)
  /// Útil para rutas más naturales en navegación
  static List<Vector3> calculateSmoothPath(
    Vector3 start,
    Vector3 end, {
    List<Vector3>? intermediatePoints,
    int smoothness = 10, // Puntos de interpolación entre cada segmento
  }) {
    // Puntos de control para la curva
    List<Vector3> controlPoints = [start];
    if (intermediatePoints != null && intermediatePoints.isNotEmpty) {
      controlPoints.addAll(intermediatePoints);
    }
    controlPoints.add(end);

    // Si solo hay 2 puntos, usar ruta directa
    if (controlPoints.length == 2) {
      return calculateDirectPath(start, end);
    }

    List<Vector3> smoothPath = [];
    
    // Generar curva suave usando interpolación Catmull-Rom
    for (int i = 0; i < controlPoints.length - 1; i++) {
      Vector3 p0 = i > 0 ? controlPoints[i - 1] : controlPoints[i];
      Vector3 p1 = controlPoints[i];
      Vector3 p2 = controlPoints[i + 1];
      Vector3 p3 = i < controlPoints.length - 2 ? controlPoints[i + 2] : controlPoints[i + 1];

      for (int j = 0; j <= smoothness; j++) {
        double t = j / smoothness;
        Vector3 point = _catmullRomSpline(p0, p1, p2, p3, t);
        smoothPath.add(point);
      }
    }

    return smoothPath;
  }

  /// Interpolación Catmull-Rom entre 4 puntos de control
  static Vector3 _catmullRomSpline(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, double t) {
    double t2 = t * t;
    double t3 = t2 * t;

    // Coeficientes de Catmull-Rom
    Vector3 result = p1 * 2.0;
    result += (p2 - p0) * t;
    result += (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t2;
    result += (p1 * 3.0 - p0 - p2 * 3.0 + p3) * t3;
    result *= 0.5;

    return result;
  }

  /// Algoritmo A* básico para pathfinding en grid
  /// Útil para expansión futura con obstáculos
  static List<Vector3>? aStarPathfinding(
    Vector3 start,
    Vector3 goal,
    Set<Vector3> obstacles, {
    double gridSize = 0.5,
    double maxSearchDistance = 50.0,
  }) {
    // Convertir a coordenadas de grid
    _GridNode startNode = _GridNode(_toGridCoord(start, gridSize));
    _GridNode goalNode = _GridNode(_toGridCoord(goal, gridSize));

    // Conjuntos para A*
    Set<_GridNode> openSet = {startNode};
    Set<_GridNode> closedSet = {};
    Map<_GridNode, _GridNode> cameFrom = {};
    Map<_GridNode, double> gScore = {startNode: 0};
    Map<_GridNode, double> fScore = {startNode: _heuristic(start, goal)};

    while (openSet.isNotEmpty) {
      // Encontrar nodo con menor fScore
      _GridNode current = openSet.reduce((a, b) => 
        (fScore[a] ?? double.infinity) < (fScore[b] ?? double.infinity) ? a : b
      );

      // Si llegamos al objetivo
      if (current == goalNode) {
        return _reconstructPath(cameFrom, current, gridSize);
      }

      openSet.remove(current);
      closedSet.add(current);

      // Explorar vecinos (8 direcciones)
      for (var neighbor in _getNeighbors(current)) {
        if (closedSet.contains(neighbor)) continue;

        Vector3 neighborPos = _fromGridCoord(neighbor.position, gridSize);
        
        // Verificar si hay obstáculo
        bool isBlocked = obstacles.any((obstacle) => 
          neighborPos.distanceTo(obstacle) < gridSize
        );
        
        if (isBlocked) continue;

        double tentativeGScore = (gScore[current] ?? double.infinity) + 
          _distance(current.position, neighbor.position) * gridSize;

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tentativeGScore >= (gScore[neighbor] ?? double.infinity)) {
          continue;
        }

        cameFrom[neighbor] = current;
        gScore[neighbor] = tentativeGScore;
        Vector3 neighborWorldPos = _fromGridCoord(neighbor.position, gridSize);
        fScore[neighbor] = tentativeGScore + _heuristic(neighborWorldPos, goal);
      }

      // Límite de búsqueda para evitar loops infinitos
      if ((gScore[current] ?? 0) > maxSearchDistance) {
        break;
      }
    }

    // No se encontró camino, retornar null
    return null;
  }

  /// Convierte posición del mundo a coordenada de grid
  static Vector3 _toGridCoord(Vector3 worldPos, double gridSize) {
    return Vector3(
      (worldPos.x / gridSize).round().toDouble(),
      (worldPos.y / gridSize).round().toDouble(),
      (worldPos.z / gridSize).round().toDouble(),
    );
  }

  /// Convierte coordenada de grid a posición del mundo
  static Vector3 _fromGridCoord(Vector3 gridCoord, double gridSize) {
    return gridCoord * gridSize;
  }

  /// Heurística de distancia Manhattan para A*
  static double _heuristic(Vector3 a, Vector3 b) {
    return (a - b).length; // Distancia euclidiana
  }

  /// Distancia entre nodos de grid
  static double _distance(Vector3 a, Vector3 b) {
    // Diagonal = sqrt(2), ortogonal = 1
    double dx = (a.x - b.x).abs();
    double dy = (a.y - b.y).abs();
    double dz = (a.z - b.z).abs();
    
    if (dx + dy + dz > 1.5) {
      return math.sqrt(2); // Movimiento diagonal
    }
    return 1.0; // Movimiento ortogonal
  }

  /// Obtiene vecinos en 8 direcciones (4 ortogonales + 4 diagonales) en plano XZ
  static List<_GridNode> _getNeighbors(_GridNode node) {
    return [
      // Ortogonales
      _GridNode(Vector3(node.position.x + 1, node.position.y, node.position.z)),
      _GridNode(Vector3(node.position.x - 1, node.position.y, node.position.z)),
      _GridNode(Vector3(node.position.x, node.position.y, node.position.z + 1)),
      _GridNode(Vector3(node.position.x, node.position.y, node.position.z - 1)),
      // Diagonales
      _GridNode(Vector3(node.position.x + 1, node.position.y, node.position.z + 1)),
      _GridNode(Vector3(node.position.x + 1, node.position.y, node.position.z - 1)),
      _GridNode(Vector3(node.position.x - 1, node.position.y, node.position.z + 1)),
      _GridNode(Vector3(node.position.x - 1, node.position.y, node.position.z - 1)),
    ];
  }

  /// Reconstruye el camino desde el mapa cameFrom
  static List<Vector3> _reconstructPath(
    Map<_GridNode, _GridNode> cameFrom,
    _GridNode current,
    double gridSize,
  ) {
    List<Vector3> path = [_fromGridCoord(current.position, gridSize)];
    
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, _fromGridCoord(current.position, gridSize));
    }
    
    return path;
  }

  /// Simplifica un camino eliminando puntos redundantes (Douglas-Peucker)
  static List<Vector3> simplifyPath(List<Vector3> path, {double epsilon = 0.5}) {
    if (path.length < 3) return path;

    return _douglasPeucker(path, epsilon);
  }

  /// Algoritmo Douglas-Peucker para simplificación de líneas
  static List<Vector3> _douglasPeucker(List<Vector3> points, double epsilon) {
    if (points.length < 3) return points;

    // Encontrar punto con máxima distancia
    double maxDistance = 0;
    int maxIndex = 0;
    
    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpdicularDistance(
        points[i],
        points.first,
        points.last,
      );
      
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // Si la distancia máxima es mayor que epsilon, subdividir
    if (maxDistance > epsilon) {
      List<Vector3> left = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      List<Vector3> right = _douglasPeucker(
        points.sublist(maxIndex),
        epsilon,
      );
      
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  /// Calcula distancia perpendicular de punto a línea
  static double _perpdicularDistance(
    Vector3 point,
    Vector3 lineStart,
    Vector3 lineEnd,
  ) {
    Vector3 lineVec = lineEnd - lineStart;
    Vector3 pointVec = point - lineStart;
    
    double lineLengthSquared = lineVec.length2;
    if (lineLengthSquared == 0) {
      return pointVec.length;
    }
    
    double t = pointVec.dot(lineVec) / lineLengthSquared;
    t = t.clamp(0.0, 1.0);
    
    Vector3 projection = lineStart + lineVec * t;
    return point.distanceTo(projection);
  }
}

/// Clase auxiliar para nodos del grid en A*
class _GridNode {
  final Vector3 position;

  _GridNode(this.position);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GridNode &&
      other.position.x == position.x &&
      other.position.y == position.y &&
      other.position.z == position.z;
  }

  @override
  int get hashCode => position.hashCode;
}
