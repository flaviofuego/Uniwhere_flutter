import 'dart:math' as math;
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

  // Calculate euclidean distance to another waypoint in meters
  double distanceTo(Waypoint other) {
    final dx = latitude - other.latitude;
    final dy = longitude - other.longitude;
    final dz = altitude - other.altitude;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  // Calculate bearing angle to another waypoint in degrees
  double bearingTo(Waypoint other) {
    final dx = other.latitude - latitude;
    final dy = other.longitude - longitude;
    return math.atan2(dy, dx) * 180 / math.pi;
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
