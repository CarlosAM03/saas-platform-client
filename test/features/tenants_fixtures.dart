import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/tenants/data/tenants_repository.dart';
import 'feature_fixtures.dart';

class FakeTenants implements TenantsRepository {
  Future<List<Tenant>> Function() fetch =
      () async => [Tenant.fromJson(tenantJson)];
  @override
  Future<List<Tenant>> list() => fetch();
  @override
  Future<Tenant> get(String id) async =>
      Tenant.fromJson({...tenantJson, 'id': id});
  @override
  Future<Tenant> create(CreateTenantRequest request) async =>
      Tenant.fromJson({...tenantJson, ...request.toJson()});
  @override
  Future<List<AuthTenant>> discover() async => (await list())
      .map((t) => AuthTenant(
          id: t.id, name: t.name, slug: t.slug, status: t.status.name))
      .toList();
}
