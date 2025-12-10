# Quick Start Guide

## ⚡ Get Started in 5 Minutes

### Prerequisites
- Flutter SDK installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio or Xcode
- Physical device (AR doesn't work well on emulators)

### Installation Steps

1. **Clone the repository**
```bash
git clone https://github.com/flaviofuego/Uniwhere_flutter.git
cd Uniwhere_flutter
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Check your Flutter setup**
```bash
flutter doctor
```

Fix any issues shown by `flutter doctor`.

4. **Connect your device**
- Enable USB debugging on Android
- Or connect iPhone with developer mode enabled

5. **Run the app**
```bash
flutter run
```

That's it! The app should now be running on your device.

## 📱 First Time Setup

### On the Device

1. **Grant Permissions**
   - Allow Camera access
   - Allow Location access

2. **Select a Destination**
   - Choose from: Kitchen, Living Room, Bedroom, Bathroom, or Entrance

3. **Start Navigation**
   - Tap "Iniciar Navegación AR"
   - Point your camera and follow the arrows!

## 🏠 Testing at Home

The app comes with pre-configured waypoints that simulate rooms:

```
Kitchen (0, 5)
     ↑
     |
Living Room (-3, 0) ← → You (0, 0) ← → Bathroom (5, 0)
     |
     ↓
Entrance (0, -5)
```

Just walk around and the app will guide you with:
- 🔵 Blue arrow pointing to destination
- 📏 Distance in meters
- 🧭 Turn-by-turn instructions

## 🎯 Quick Tips

1. **Calibrate your phone's compass** - Move it in a figure-8 motion
2. **Stay away from metal objects** - They interfere with sensors
3. **Good lighting helps** - Camera tracking works better
4. **Hold phone upright** - For best AR experience

## 🐛 Troubleshooting

**App crashes on start?**
→ Check permissions are granted in Settings

**Camera not working?**
→ Restart the app or your device

**Arrow pointing wrong direction?**
→ Calibrate compass and move away from metal

## 📚 Next Steps

- Read [INSTRUCTIONS.md](INSTRUCTIONS.md) for detailed usage guide
- Check [DEVELOPMENT.md](DEVELOPMENT.md) if you want to modify the code
- Customize waypoints in `lib/models/waypoint_data.dart`

## 🚀 Build for Release

### Android APK
```bash
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```
Then open Xcode and archive.

---

**Need help?** Open an issue on GitHub!
