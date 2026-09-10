class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    const value = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
    return const AppConfig(apiBaseUrl: value);
  }
}
