# Uniwhere AR Navigation - AI Agent Instructions

## Project Overview
Flutter-based AR indoor navigation demo with Visual Positioning System (VPS) simulation. Designed for university campus wayfinding using ARCore/ARKit. **This is a functional prototype** - AR and VPS services contain simulations ready for production integration.

## Critical Architecture Patterns

### Service Layer (Singleton via Provider)
All services are injected in `main.dart` via `MultiProvider`:
- **ARService** (`lib/services/ar_service.dart`) - Uses `ar_flutter_plugin_plus`, manages AR session/tracking
- **NavigationService** - Pathfinding with A*, waypoint management, distance calculations
- **VPSService** - Visual positioning framework (ready for ML Kit integration)
- **StorageService** - Hive NoSQL persistence (requires Adapter generation - see below)
- **PermissionsService** - Camera/location permission handling

**Never instantiate services directly** - always access via `Provider.of<ServiceName>(context, listen: false)` or `context.read<ServiceName>()`.

### Data Models & Hive Serialization
**RoomLocation** (`lib/models/room_location.dart`) is Hive-serialized with `@HiveType(typeId: 0)`:
```dart
part 'room_location.g.dart'; // Generated file
```

**If you modify RoomLocation fields**, regenerate adapter:
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

The adapter **must be registered before Hive.initFlutter()** in `main.dart` (already done).

### 3D Coordinate System
- **Local origin** set in AR space via `ARService.setOrigin()`
- All positions use **Vector3** from `vector_math` package
- **Y-axis is vertical** (Y=1.5m typical for AR objects at eye level)
- Distance calculations in meters
- See `lib/utils/vector3_helper.dart` for common transformations

### AR Widget Pattern (ar_navigation_arrow.dart)
The AR navigation widget demonstrates the **camera-following pattern**:
1. Uses `getCameraPose()` to retrieve camera position/rotation every 100ms
2. Positions 3D arrow **1.5m in front of camera** (`cameraPosition + cameraForward * 1.5`)
3. Recreates `ARNode` each frame (remove old node, add new one with updated transform)
4. Falls back to animated 2D arrow if 3D fails

**Key insight**: For objects that follow the camera, **don't use anchors** - use direct node positioning relative to camera pose.

## Development Workflows

### Running the App
```powershell
# Check connected device (emulators won't work for AR)
flutter devices

# Run with verbose logging
flutter run -v

# Hot reload works for UI, but AR initialization requires full restart
```

### Debugging AR Issues
Look for emoji-prefixed debug logs:
- `🎯` - AR object creation/positioning
- `✅` - Successful operations
- `❌` - Errors with stack traces
- `⚠️` - Warnings

All AR components use `debugPrint` extensively - check terminal output first.

### Asset Management
3D models go in `assets/models/`:
- **arrow.glb** - Navigation arrow (scale: 0.02 in code)
- Use `.glb` format (not `.gltf`) for compatibility with `ar_flutter_plugin_plus`
- Models are loaded via `NodeType.localGLB` in ARNode creation

## Project-Specific Conventions

### Navigation Distance Thresholds (lib/utils/constants.dart)
```dart
destinationThreshold = 1.0m   // Arrival detection
nearThreshold = 3.0m          // Green arrow
mediumThreshold = 10.0m       // Yellow arrow
// > 10m = Red arrow
```

These drive UI color changes and completion detection - **don't modify without updating dependent logic**.

### Category System
RoomLocation categories (`habitacion`, `servicio`, `recreacion`, `trabajo`) determine:
- Icon colors via `getCategoryColor()`
- Filtering in HomeScreen
- Visual appearance in map view

Add new categories by updating `AppConstants.categoryColors` and icon mappings.

### State Management
Uses **Provider** (no Bloc/Riverpod):
- Screens consume services via `context.read<>()` for methods
- Use `context.watch<>()` sparingly - services don't extend ChangeNotifier
- State is mostly **pull-based** (polling position) not reactive

## Integration Points

### AR Plugin Lifecycle
```dart
// In StatefulWidget
ARView(
  onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) {
    // Store managers, then:
    sessionManager.onInitialize(
      showPlanes: true,
      showWorldOrigin: true,
      handleTaps: false,
    );
    objectManager.onInitialize();
  }
)
```

Call `ARService.onARViewCreated()` to let service manage these managers.

### VPS Reference Images
Capture via `image_picker`, store path in `RoomLocation.imageReference`:
```dart
final image = await ImagePicker().pickImage(source: ImageSource.camera);
// Store image.path in location object
```

VPS service checks similarity when `recognizeOnce()` is called - currently simulated with random confidence.

## Known Limitations & TODOs

1. **Hive Adapter Missing**: `room_location.g.dart` not in repo - generate locally (see command above)
2. **VPS is Simulated**: Integration with Google ML Kit pending (see `TODO.md` line 29)
3. **A* Pathfinding Incomplete**: Direct line routing only - obstruction avoidance not implemented
4. **AR Objects Don't Persist**: No Cloud Anchors - locations reset on app restart
5. **No Backend**: All data local-only (see `TODO.md` section 8 for API service structure)

## Common Tasks

### Adding a New Screen
1. Create in `lib/screens/`
2. Add route to `MaterialApp.routes` in `main.dart`
3. Access services via `Provider.of<>(context)`
4. Use `AppConstants` for colors/spacing

### Modifying AR Object Scale
Edit `scale` parameter in `ARNode` creation:
```dart
scale: Vector3.all(0.02)  // Current arrow scale
```

Scale is **multiplicative** - 0.01 = 50% smaller, 0.04 = 2x larger.

### Testing Without Physical Device
Most UI works in emulator except:
- ARView (shows black screen - expected)
- Camera capture (use gallery picker as fallback)
- Location services (can mock with hardcoded Vector3)

## Files to Read First
1. `PROJECT_SUMMARY.md` - Architecture overview
2. `DEVELOPMENT.md` - Technical deep-dive
3. `lib/utils/constants.dart` - All magic numbers/thresholds
4. `lib/services/ar_service.dart` - AR implementation patterns
5. `lib/widgets/ar_navigation_arrow.dart` - Complete AR widget example
