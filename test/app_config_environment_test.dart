import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';

void main() {
  test('API_BASE_URL comes from the compile-time environment', () {
    const compiled = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
    expect(AppConfig.fromEnvironment().apiBaseUrl, compiled);
  });
}
