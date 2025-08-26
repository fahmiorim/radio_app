class AppApiConfig {
  /// Base URL for API requests. Can be overridden by passing
  /// `--dart-define=BASE_URL=your_url` at build time.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.89.137:8000/api/v1/mobile',
  );

  /// Base URL for storage. Can be overridden by passing
  /// `--dart-define=BASE_URL_STORAGE=your_url` at build time.
  static const String baseUrlStorage = String.fromEnvironment(
    'BASE_URL_STORAGE',
    defaultValue: 'http://192.168.89.137:8000/storage',
  );
}
