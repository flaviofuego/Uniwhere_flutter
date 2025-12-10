import 'package:flutter_test/flutter_test.dart';
import 'package:uniwhere_ar_wayfinding/models/waypoint.dart';
import 'package:uniwhere_ar_wayfinding/models/waypoint_data.dart';

void main() {
  group('Waypoint Model Tests', () {
    test('Waypoint should be created with correct properties', () {
      final waypoint = Waypoint(
        id: 'test1',
        name: 'Test Location',
        description: 'A test location',
        latitude: 1.0,
        longitude: 2.0,
        altitude: 0.0,
      );

      expect(waypoint.id, 'test1');
      expect(waypoint.name, 'Test Location');
      expect(waypoint.latitude, 1.0);
      expect(waypoint.longitude, 2.0);
    });

    test('Distance calculation should work correctly', () {
      final waypoint1 = Waypoint(
        id: '1',
        name: 'Point A',
        description: 'First point',
        latitude: 0.0,
        longitude: 0.0,
      );

      final waypoint2 = Waypoint(
        id: '2',
        name: 'Point B',
        description: 'Second point',
        latitude: 3.0,
        longitude: 4.0,
      );

      final distance = waypoint1.distanceTo(waypoint2);
      expect(distance, 5.0); // sqrt(3^2 + 4^2) = 5
    });

    test('Bearing calculation should work correctly', () {
      final waypoint1 = Waypoint(
        id: '1',
        name: 'Point A',
        description: 'First point',
        latitude: 0.0,
        longitude: 0.0,
      );

      final waypoint2 = Waypoint(
        id: '2',
        name: 'Point B',
        description: 'Second point',
        latitude: 1.0,
        longitude: 0.0,
      );

      final bearing = waypoint1.bearingTo(waypoint2);
      expect(bearing, closeTo(0.0, 0.1)); // Pointing east (along latitude axis)
    });
  });

  group('WaypointData Tests', () {
    test('Sample waypoints should be available', () {
      expect(WaypointData.sampleWaypoints.isNotEmpty, true);
      expect(WaypointData.sampleWaypoints.length, greaterThanOrEqualTo(5));
    });

    test('Should retrieve waypoint by id', () {
      final waypoint = WaypointData.getWaypointById('1');
      expect(waypoint, isNotNull);
      expect(waypoint?.id, '1');
    });

    test('Should return null for invalid id', () {
      final waypoint = WaypointData.getWaypointById('invalid');
      expect(waypoint, isNull);
    });

    test('All sample waypoints should have unique ids', () {
      final ids = WaypointData.sampleWaypoints.map((w) => w.id).toSet();
      expect(ids.length, WaypointData.sampleWaypoints.length);
    });
  });
}
