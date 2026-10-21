import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../data/campaigns_repository.dart';

final campaignsRepositoryProvider = Provider<CampaignsRepository>((ref) {
  final scope = ref.watch(sessionScopeProvider);
  if (scope?.tenantId == null) {
    throw StateError('A selected tenant is required');
  }
  return ApiCampaignsRepository(ref.watch(platformApiProvider));
});
final campaignsListProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Campaign>, PageKey>((ref, key) {
  ref.watch(sessionScopeProvider);
  return ref.watch(campaignsRepositoryProvider).list(query: pageQuery(key));
});
final campaignsDetailProvider =
    FutureProvider.autoDispose.family<Campaign, String>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(campaignsRepositoryProvider).get(id);
});
final campaignProspectsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Prospect>, ({String id, PageKey query})>(
        (ref, key) {
  ref.watch(sessionScopeProvider);
  return ref
      .watch(campaignsRepositoryProvider)
      .prospects(key.id, query: pageQuery(key.query));
});
