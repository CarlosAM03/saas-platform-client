import 'package:dio/dio.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import '../platform_api/fixtures.dart';
export '../platform_api/fixtures.dart';

AuthContext session({String? tenant = 'a', String? platformRole}) =>
    AuthContext.fromJson({
      ...authJson,
      'user': {...(authJson['user'] as Map), 'platformRole': platformRole},
      'currentTenantId': tenant
    });

class FeatureAuthController extends AuthController {
  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, context: session());
  void setSession(AuthContext context) =>
      state = AuthState(status: AuthStatus.authenticated, context: context);
  void setStatus(AuthStatus status) => state = AuthState(status: status);
  @override
  Future<void> selectTenant(String id) async => setSession(session(tenant: id));
}

PlatformApi testApi(ContractAdapter adapter) => PlatformApi(ApiClient(
    config: const AppConfig(apiBaseUrl: 'http://localhost'),
    storage: TestTokenStorage(),
    dio: Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter));
