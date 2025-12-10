# Assets Directory

This directory is for storing app assets like images, icons, and other resources.

Currently, the app doesn't require custom images as it uses Flutter's built-in Material icons.

## Adding Assets

To add assets to your app:

1. Place your files in this directory
2. Update `pubspec.yaml` to include them:

```yaml
flutter:
  assets:
    - assets/
    - assets/images/
    - assets/icons/
```

3. Use them in your code:

```dart
Image.asset('assets/images/my_image.png')
```
