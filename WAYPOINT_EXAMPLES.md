# Example Waypoint Configuration

This file shows examples of how to configure waypoints for different environments.

## Format

```dart
Waypoint(
  id: 'unique_id',           // Unique identifier
  name: 'Display Name',      // Name shown in UI
  description: 'Details',    // Description text
  latitude: 0.0,             // X coordinate (East-West)
  longitude: 0.0,            // Y coordinate (North-South)
  altitude: 0.0,             // Z coordinate (height/floor)
  icon: Icons.place,         // Material icon
)
```

## Coordinate System

```
        North (+Y, longitude)
              ↑
              |
West ←--------•--------→ East (+X, latitude)
  (-X)        |        
              |
              ↓
        South (-Y)
```

- **Origin (0,0)**: Center of your environment
- **Units**: Meters
- **Altitude**: For multi-floor buildings

## Example 1: Small Apartment

```dart
// 50 m² apartment
List<Waypoint> apartmentWaypoints = [
  Waypoint(
    id: '1',
    name: 'Living Room',
    description: 'Main living area',
    latitude: 0.0,
    longitude: 0.0,
    altitude: 0.0,
    icon: Icons.chair,
  ),
  Waypoint(
    id: '2',
    name: 'Kitchen',
    description: 'Cooking area',
    latitude: 4.0,
    longitude: 3.0,
    altitude: 0.0,
    icon: Icons.kitchen,
  ),
  Waypoint(
    id: '3',
    name: 'Bedroom',
    description: 'Sleeping area',
    latitude: -4.0,
    longitude: 3.0,
    altitude: 0.0,
    icon: Icons.bed,
  ),
  Waypoint(
    id: '4',
    name: 'Bathroom',
    description: 'Bathroom',
    latitude: -4.0,
    longitude: -2.0,
    altitude: 0.0,
    icon: Icons.bathroom,
  ),
];
```

## Example 2: Office Floor

```dart
// Open office layout
List<Waypoint> officeWaypoints = [
  Waypoint(
    id: '1',
    name: 'Reception',
    description: 'Main entrance',
    latitude: 0.0,
    longitude: -10.0,
    altitude: 0.0,
    icon: Icons.desk,
  ),
  Waypoint(
    id: '2',
    name: 'Meeting Room A',
    description: 'Large conference room',
    latitude: 8.0,
    longitude: 0.0,
    altitude: 0.0,
    icon: Icons.meeting_room,
  ),
  Waypoint(
    id: '3',
    name: 'Kitchen',
    description: 'Break room',
    latitude: -8.0,
    longitude: 0.0,
    altitude: 0.0,
    icon: Icons.kitchen,
  ),
  Waypoint(
    id: '4',
    name: 'Server Room',
    description: 'IT equipment',
    latitude: 0.0,
    longitude: 10.0,
    altitude: 0.0,
    icon: Icons.dns,
  ),
  Waypoint(
    id: '5',
    name: 'Emergency Exit',
    description: 'Fire exit',
    latitude: 15.0,
    longitude: -5.0,
    altitude: 0.0,
    icon: Icons.exit_to_app,
  ),
];
```

## Example 3: University Building (Multi-floor)

```dart
// Building with 3 floors
List<Waypoint> universityWaypoints = [
  // Ground Floor (altitude: 0.0)
  Waypoint(
    id: '1',
    name: 'Main Entrance',
    description: 'Ground floor entrance',
    latitude: 0.0,
    longitude: -20.0,
    altitude: 0.0,
    icon: Icons.door_front,
  ),
  Waypoint(
    id: '2',
    name: 'Library',
    description: 'Main library',
    latitude: -15.0,
    longitude: 0.0,
    altitude: 0.0,
    icon: Icons.local_library,
  ),
  
  // First Floor (altitude: 4.0)
  Waypoint(
    id: '3',
    name: 'Classroom 101',
    description: 'Computer lab',
    latitude: 10.0,
    longitude: 5.0,
    altitude: 4.0,
    icon: Icons.computer,
  ),
  Waypoint(
    id: '4',
    name: 'Auditorium',
    description: 'Main auditorium',
    latitude: 0.0,
    longitude: 10.0,
    altitude: 4.0,
    icon: Icons.theater_comedy,
  ),
  
  // Second Floor (altitude: 8.0)
  Waypoint(
    id: '5',
    name: 'Administration',
    description: 'Admin offices',
    latitude: -10.0,
    longitude: 0.0,
    altitude: 8.0,
    icon: Icons.business,
  ),
];
```

## Example 4: Shopping Mall

```dart
// Large shopping center
List<Waypoint> mallWaypoints = [
  Waypoint(
    id: '1',
    name: 'North Entrance',
    description: 'Main entrance',
    latitude: 0.0,
    longitude: 50.0,
    altitude: 0.0,
    icon: Icons.door_front,
  ),
  Waypoint(
    id: '2',
    name: 'Food Court',
    description: 'Dining area',
    latitude: -20.0,
    longitude: 0.0,
    altitude: 0.0,
    icon: Icons.restaurant,
  ),
  Waypoint(
    id: '3',
    name: 'Restrooms',
    description: 'Public restrooms',
    latitude: 25.0,
    longitude: -15.0,
    altitude: 0.0,
    icon: Icons.wc,
  ),
  Waypoint(
    id: '4',
    name: 'Cinema',
    description: 'Movie theater',
    latitude: 30.0,
    longitude: 20.0,
    altitude: 0.0,
    icon: Icons.movie,
  ),
  Waypoint(
    id: '5',
    name: 'Parking',
    description: 'Parking entrance',
    latitude: 0.0,
    longitude: -50.0,
    altitude: -4.0,
    icon: Icons.local_parking,
  ),
];
```

## How to Measure Your Space

### Method 1: Tape Measure
1. Choose a central point as origin (0,0)
2. Measure distance East/West for latitude
3. Measure distance North/South for longitude
4. Record in meters

### Method 2: Step Counting
1. Average step ≈ 0.75 meters
2. Count steps from origin to location
3. Multiply by 0.75
4. Record direction (+ or -)

### Method 3: Floor Plan
1. Get building floor plan
2. Use scale to calculate distances
3. Convert to meters
4. Map to coordinate system

## Tips

1. **Keep it simple**: Start with 3-5 waypoints
2. **Test incrementally**: Add one waypoint at a time
3. **Use relative positions**: Exact GPS not needed for indoor
4. **Consider obstacles**: Walls, furniture affect navigation
5. **Multi-floor**: Use altitude for different levels (≈4m per floor)

## Available Icons

Common Material icons you can use:
- `Icons.home`
- `Icons.door_front`
- `Icons.kitchen`
- `Icons.bed`
- `Icons.bathroom`
- `Icons.chair`
- `Icons.desk`
- `Icons.meeting_room`
- `Icons.restaurant`
- `Icons.local_cafe`
- `Icons.local_library`
- `Icons.computer`
- `Icons.business`
- `Icons.school`
- `Icons.local_hospital`
- `Icons.exit_to_app`
- `Icons.elevator`
- `Icons.stairs`
- `Icons.wc`
- `Icons.local_parking`

See all icons: https://api.flutter.dev/flutter/material/Icons-class.html

---

Edit `lib/models/waypoint_data.dart` to customize your waypoints!
