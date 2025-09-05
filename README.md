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

## Configuration

The application requires API and asset URLs along with Pusher credentials to be provided at runtime. Set `API_BASE_URL`, `ASSET_BASE_URL`, `PUSHER_APP_KEY`, `PUSHER_CLUSTER`, and `PUSHER_AUTH_ENDPOINT` using either `--dart-define` when launching the app or a `.env` file in the project root.

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
