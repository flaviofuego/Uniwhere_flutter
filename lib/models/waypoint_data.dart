import 'package:flutter/material.dart';
import '../models/waypoint.dart';

class WaypointData {
  // Sample waypoints for testing in a home environment
  // These represent different rooms/locations in a house
  static final List<Waypoint> sampleWaypoints = [
    Waypoint(
      id: '1',
      name: 'Cocina',
      description: 'La cocina principal',
      latitude: 0.0,
      longitude: 5.0,
      altitude: 0.0,
      icon: Icons.kitchen,
    ),
    Waypoint(
      id: '2',
      name: 'Sala de Estar',
      description: 'Sala principal de la casa',
      latitude: -3.0,
      longitude: 0.0,
      altitude: 0.0,
      icon: Icons.chair,
    ),
    Waypoint(
      id: '3',
      name: 'Dormitorio',
      description: 'Habitación principal',
      latitude: 3.0,
      longitude: 3.0,
      altitude: 0.0,
      icon: Icons.bed,
    ),
    Waypoint(
      id: '4',
      name: 'Baño',
      description: 'Baño principal',
      latitude: 5.0,
      longitude: 0.0,
      altitude: 0.0,
      icon: Icons.bathroom,
    ),
    Waypoint(
      id: '5',
      name: 'Entrada',
      description: 'Entrada principal',
      latitude: 0.0,
      longitude: -5.0,
      altitude: 0.0,
      icon: Icons.door_front,
    ),
  ];

  static Waypoint? getWaypointById(String id) {
    try {
      return sampleWaypoints.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }
}
