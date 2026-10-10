import '../core/network/api_client.dart';
import '../shared/models/api_models.dart' show unwrapObject, unwrapList;
import 'models.dart';
import 'requests.dart';
import 'src/api_support.dart';

class TenantsApi {
  const TenantsApi(this._client);
  final ApiClient _client;
  Future<List<Tenant>> list() async =>
      unwrapList(await _client.get('/api/v1/tenants'), Tenant.fromJson);
  Future<Tenant> get(String id) async => Tenant.fromJson(
      unwrapObject(await _client.get(entityPath('tenants', id))));
  Future<Tenant> create(CreateTenantRequest request) async =>
      Tenant.fromJson(unwrapObject(
          await _client.post('/api/v1/tenants', data: request.toJson())));
}
