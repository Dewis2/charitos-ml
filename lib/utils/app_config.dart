class AppConfig {
  const AppConfig._();

  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://example-backend.invalid',
  );
}
