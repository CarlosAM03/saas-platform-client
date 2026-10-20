import '../../../core/network/api_client.dart';
import '../../../platform_api/platform_api.dart';

abstract class TenantsRepository {
  factory TenantsRepository(ApiClient client) = ApiTenantsRepository.fromClient;
  Future<List<Tenant>> list();
  Future<Tenant> get(String id);
  Future<Tenant> create(CreateTenantRequest request);
  Future<List<AuthTenant>> discover();
}

class ApiTenantsRepository implements TenantsRepository {
  ApiTenantsRepository(PlatformApi api) : _api = api.tenants;
  ApiTenantsRepository.fromClient(ApiClient client) : _api = TenantsApi(client);
  final TenantsApi _api;
  @override
  Future<List<Tenant>> list() => _api.list();
  @override
  Future<Tenant> get(String id) => _api.get(id);
  @override
  Future<Tenant> create(CreateTenantRequest request) => _api.create(request);
  @override
  Future<List<AuthTenant>> discover() async => (await list())
      .map((t) => AuthTenant(
          id: t.id, name: t.name, slug: t.slug, status: t.status.name))
      .toList(growable: false);
}
