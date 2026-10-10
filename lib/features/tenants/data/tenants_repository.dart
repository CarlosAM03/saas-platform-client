import '../../../core/network/api_client.dart';
import '../../../shared/models/api_models.dart';

class TenantsRepository {
  const TenantsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AuthTenant>> discover() async {
    final response = await _apiClient.get('/api/v1/tenants');
    return unwrapList(response, AuthTenant.fromJson);
  }
}
