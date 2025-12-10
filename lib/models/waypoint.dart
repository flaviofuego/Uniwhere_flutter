import 'package:flutter/material.dart';

class Waypoint {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double altitude;
  final IconData icon;

  Waypoint({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.icon = Icons.place,
  });

  // Calculate distance to another waypoint (simple euclidean distance)
  double distanceTo(Waypoint other) {
    final dx = latitude - other.latitude;
    final dy = longitude - other.longitude;
    final dz = altitude - other.altitude;
    return (dx * dx + dy * dy + dz * dz);
  }

  // Calculate bearing angle to another waypoint
  double bearingTo(Waypoint other) {
    final dx = other.latitude - latitude;
    final dy = other.longitude - longitude;
    return (dy.atan2(dx) * 180 / 3.14159265359);
  }
}

class ARMarker {
  final Waypoint waypoint;
  final double distanceInMeters;
  final double bearingInDegrees;
  final Color color;

  ARMarker({
    required this.waypoint,
    required this.distanceInMeters,
    required this.bearingInDegrees,
    this.color = Colors.blue,
  });
}
