import '../../../core/network/api_client.dart';
import '../../../shared/models/api_models.dart';
import '../../../platform_api/auth_api.dart';
import '../../../platform_api/requests.dart';

class AuthRepository {
  AuthRepository(ApiClient client) : _api = AuthApi(client);
  final AuthApi _api;

  Future<AuthContext> login(
      {required String email, required String password}) async {
    return _api.login(LoginRequest(email: email, password: password));
  }

  Future<AuthContext> me() async {
    return _api.me();
  }

  Future<AuthContext> selectTenant(String tenantId) async {
    return _api.selectTenant(SelectTenantRequest(tenantId: tenantId));
  }

  Future<void> logout() async {
    await _api.logout();
  }
}
