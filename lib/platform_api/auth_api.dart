import '../core/network/api_client.dart';
import '../shared/models/api_models.dart';
import 'requests.dart';
import 'src/api_support.dart';
import 'src/json_fields.dart';
import 'models.dart' show UserStatus, TenantStatus, PlatformRole;

AuthContext _context(Object? response) {
  final json = unwrapObject(response);
  nullableValue<String>(json, 'currentTenantId');
  final user = jsonObject(json['user']);
  final role = nullableValue<String>(user, 'platformRole');
  if (role != null) {
    enumValue(role, PlatformRole.values);
  }
  enumValue(user['status'], UserStatus.values);
  for (final tenant in requiredValue<List<dynamic>>(json, 'tenants')) {
    enumValue(jsonObject(tenant)['status'], TenantStatus.values);
  }
  return AuthContext.fromJson(json);
}

class AuthApi {
  const AuthApi(this._client);
  final ApiClient _client;
  Future<AuthContext> login(LoginRequest request) async => _context(
      await _client.post('/api/v1/auth/login', data: request.toJson()));
  Future<AuthContext> me() async =>
      _context(await _client.get('/api/v1/auth/me'));
  Future<AuthContext> selectTenant(SelectTenantRequest request) async =>
      _context(await _client.post('/api/v1/auth/select-tenant',
          data: request.toJson()));
  Future<void> logout() async =>
      parseEmpty(await _client.post('/api/v1/auth/logout'));
}
