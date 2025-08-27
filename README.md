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

The application requires API endpoints to be provided at runtime. Set `BASE_URL` using either `--dart-define` when launching the app or a
`.env` file in the project root.

### Using `--dart-define`

```bash
flutter run \
  --dart-define=BASE_URL=https://example.com \

```

### Using a `.env` file

Create a `.env` file in the project root:

```env
BASE_URL=https://example.com
```
