import '../../../core/network/api_client.dart';
import '../../../shared/models/api_models.dart';
import '../../../platform_api/tenants_api.dart';

class TenantsRepository {
  TenantsRepository(ApiClient client) : _api = TenantsApi(client);

  final TenantsApi _api;

  Future<List<AuthTenant>> discover() async {
    return (await _api.list())
        .map((tenant) => AuthTenant(
            id: tenant.id,
            name: tenant.name,
            slug: tenant.slug,
            status: tenant.status.name))
        .toList(growable: false);
  }
}
