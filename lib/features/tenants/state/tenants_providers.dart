import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../auth/state/tenant_permissions.dart';

final tenantsListProvider = FutureProvider.autoDispose<List<Tenant>>((ref) {
  if (ref.watch(sessionScopeProvider) == null) {
    throw StateError('An authenticated session is required');
  }
  return ref.watch(tenantsRepositoryProvider).list();
});
final tenantDetailProvider =
    FutureProvider.autoDispose.family<Tenant, String>((ref, id) {
  if (ref.watch(sessionScopeProvider) == null) {
    throw StateError('An authenticated session is required');
  }
  return ref.watch(tenantsRepositoryProvider).get(id);
});
