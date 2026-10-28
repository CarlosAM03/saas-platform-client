import 'package:saas_platform_client/core/config/app_config.dart';

void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Provide API_BASE_URL');
  AppConfig.validateApiBaseUrl(args.single, requireHttps: true);
}
