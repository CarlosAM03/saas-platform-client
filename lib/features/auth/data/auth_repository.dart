import '../../../core/network/api_client.dart';
import '../../../shared/models/api_models.dart';

class AuthRepository {
  const AuthRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<AuthContext> login({required String email, required String password}) async {
    final response = await _apiClient.post('/api/v1/auth/login', data: {'email': email, 'password': password});
    return AuthContext.fromJson(unwrapData(response));
  }

  Future<AuthContext> me() async {
    final response = await _apiClient.get('/api/v1/auth/me');
    return AuthContext.fromJson(unwrapData(response));
  }

  Future<AuthContext> selectTenant(String tenantId) async {
    final response = await _apiClient.post('/api/v1/auth/select-tenant', data: {'tenantId': tenantId});
    return AuthContext.fromJson(unwrapData(response));
  }

  Future<void> logout() async {
    await _apiClient.post('/api/v1/auth/logout');
  }
}
