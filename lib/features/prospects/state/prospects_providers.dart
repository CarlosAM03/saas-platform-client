import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../data/prospects_repository.dart';

final prospectsRepositoryProvider = Provider<ProspectsRepository>((ref) {
  final scope = ref.watch(sessionScopeProvider);
  if (scope?.tenantId == null) {
    throw StateError('A selected tenant is required');
  }
  return ApiProspectsRepository(ref.watch(platformApiProvider));
});
final prospectsListProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Prospect>, PageKey>((ref, key) {
  ref.watch(sessionScopeProvider);
  return ref.watch(prospectsRepositoryProvider).list(query: pageQuery(key));
});
final prospectsDetailProvider =
    FutureProvider.autoDispose.family<Prospect, String>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(prospectsRepositoryProvider).get(id);
});
