class AppConfig {
  const AppConfig({required this.apiBaseUrl});
  final String apiBaseUrl;

  static String validateApiBaseUrl(String value, {bool requireHttps = false}) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        value != value.trim()) {
      throw ArgumentError(
        'API_BASE_URL debe ser un origen HTTP/HTTPS sin /api/v1, credenciales, query ni fragmento.',
      );
    }
    final loopback = ['localhost', '127.0.0.1', '::1'].contains(uri.host);
    if ((requireHttps || !loopback) && uri.scheme != 'https') {
      throw ArgumentError('API_BASE_URL debe usar HTTPS fuera de localhost.');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  factory AppConfig.fromEnvironment() {
    const value = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
    return AppConfig(apiBaseUrl: validateApiBaseUrl(value));
  }
}
