# radio_odan_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and set up your editor.
2. Clone this repository.
3. Run `flutter pub get` to fetch project dependencies.

## Configuration

The application requires API and asset URLs along with Pusher credentials to be provided at runtime. Set `API_BASE_URL`,
`ASSET_BASE_URL`, `PUSHER_APP_KEY`, `PUSHER_CLUSTER`, and `PUSHER_AUTH_ENDPOINT` using either `--dart-define` when launching the app or a `.env` file in the project root.

### Using `--dart-define`

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=ASSET_BASE_URL=https://example.com \
  --dart-define=PUSHER_APP_KEY=exampleKey \
  --dart-define=PUSHER_CLUSTER=exampleCluster \
  --dart-define=PUSHER_AUTH_ENDPOINT=https://example.com/broadcasting/auth
```

### Using a `.env` file

Create a `.env` file in the project root:

```env
API_BASE_URL=https://api.example.com
ASSET_BASE_URL=https://example.com

PUSHER_APP_KEY=exampleKey
PUSHER_CLUSTER=exampleCluster
PUSHER_AUTH_ENDPOINT=https://example.com/broadcasting/auth
```

## Signing and Play Store Build

### Signing the App

1. Generate a keystore:

```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` with your signing information:

```properties
storeFile=/absolute/path/to/key.jks
storePassword=your-store-password
keyAlias=upload
keyPassword=your-key-password
```

3. The Android build is configured to read these values during release builds.

### Building for Play Store

Use Flutter's build commands to produce release artifacts:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=ASSET_BASE_URL=https://example.com \
  --dart-define=PUSHER_APP_KEY=exampleKey \
  --dart-define=PUSHER_CLUSTER=exampleCluster \
  --dart-define=PUSHER_AUTH_ENDPOINT=https://example.com/broadcasting/auth

# or build a release APK
flutter build apk --release
```

Upload the generated bundle or APK from `build/app/outputs/` to the Play Store.

## Development

### Running Tests

```bash
flutter test
```

### Generating Launcher Icons

The project uses [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons). After updating `flutter_launcher_icons.yaml`, generate icons with:

```bash
flutter pub run flutter_launcher_icons
```
