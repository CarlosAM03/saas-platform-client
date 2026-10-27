import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/api_models.dart';

typedef Json = Map<String, dynamic>;
typedef ListQuery = ({int page, String search});
const firstPage = (page: 1, search: '');

class PageResult {
  const PageResult(this.items, this.meta);
  final List<Json> items;
  final PaginationMeta meta;
  factory PageResult.fromResponse(Object? response) {
    final body = Map<String, dynamic>.from(response as Map);
    return PageResult(
      (body['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      PaginationMeta.fromJson(Map<String, dynamic>.from(body['meta'] as Map)),
    );
  }
}

/// All feature requests go through the foundation ApiClient. No mock fallback.
class PlatformRepository {
  const PlatformRepository(this.api);
  final ApiClient api;

  Future<PageResult> list(String resource, ListQuery query,
          {int limit = 20}) async =>
      PageResult.fromResponse(
          await api.get('/api/v1/$resource', queryParameters: {
        'page': query.page,
        'limit': limit,
        if (query.search.isNotEmpty) 'search': query.search,
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      }));
  Future<Json> detail(String resource, String id) async =>
      unwrapData(await api.get('/api/v1/$resource/${Uri.encodeComponent(id)}'));
  Future<Json> create(String resource, Json data) async =>
      unwrapData(await api.post('/api/v1/$resource', data: data));
  Future<Json> update(String resource, String id, Json data) async =>
      unwrapData(await api.patch('/api/v1/$resource/${Uri.encodeComponent(id)}',
          data: data));
  Future<void> archiveCampaign(String id, {bool permanent = false}) async {
    await api.delete(
        '/api/v1/campaigns/${Uri.encodeComponent(id)}?permanent=$permanent');
  }

  Future<void> deactivateUser(String id) async {
    await api.delete('/api/v1/users/${Uri.encodeComponent(id)}');
  }

  Future<List<Json>> organizations() async {
    final body =
        Map<String, dynamic>.from(await api.get('/api/v1/tenants') as Map);
    return (body['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

final platformRepositoryProvider =
    Provider((ref) => PlatformRepository(ref.watch(apiClientProvider)));

// Session-scoped providers discard previous organizations' data on switch/logout.
void watchSession(Ref ref) {
  ref.watch(authControllerProvider
      .select((s) => (s.context?.user.id, s.context?.currentTenantId)));
}

final organizationsProvider = FutureProvider.autoDispose<List<Json>>((ref) {
  watchSession(ref);
  return ref.watch(platformRepositoryProvider).organizations();
});
final currentOrganizationProvider = FutureProvider.autoDispose<Json?>((ref) {
  final id = ref
      .watch(authControllerProvider.select((s) => s.context?.currentTenantId));
  if (id == null) return null;
  return ref.watch(platformRepositoryProvider).detail('tenants', id);
});
final currentMembershipProvider = FutureProvider.autoDispose<Json?>((ref) {
  final session = ref.watch(authControllerProvider.select((s) => s.context));
  if (session?.currentTenantId == null) return null;
  return ref
      .watch(platformRepositoryProvider)
      .detail('users', session!.user.id);
});
final canManageUsersProvider = Provider<bool>((ref) {
  final admin = ref.watch(authControllerProvider
      .select((s) => s.context?.user.platformRole == 'ADMIN'));
  final membership = ref.watch(currentMembershipProvider).valueOrNull;
  return admin || (membership?['role'] as Map?)?['name'] == 'OWNER';
});
final campaignsProvider =
    FutureProvider.autoDispose.family<PageResult, ListQuery>((ref, query) {
  watchSession(ref);
  return ref.watch(platformRepositoryProvider).list('campaigns', query);
});
final campaignProvider =
    FutureProvider.autoDispose.family<Json, String>((ref, id) {
  watchSession(ref);
  return ref.watch(platformRepositoryProvider).detail('campaigns', id);
});
final prospectsProvider = FutureProvider.autoDispose
    .family<PageResult, ({ListQuery query, String? campaignId})>((ref, args) {
  watchSession(ref);
  final resource = args.campaignId == null
      ? 'prospects'
      : 'campaigns/${Uri.encodeComponent(args.campaignId!)}/prospects';
  return ref.watch(platformRepositoryProvider).list(resource, args.query);
});
final prospectProvider =
    FutureProvider.autoDispose.family<Json, String>((ref, id) {
  watchSession(ref);
  return ref.watch(platformRepositoryProvider).detail('prospects', id);
});
final usersProvider =
    FutureProvider.autoDispose.family<PageResult, ListQuery>((ref, query) {
  watchSession(ref);
  return ref.watch(platformRepositoryProvider).list('users', query);
});
final jobsProvider =
    FutureProvider.autoDispose.family<PageResult, int>((ref, page) {
  watchSession(ref);
  return ref
      .watch(platformRepositoryProvider)
      .list('prospecting-jobs', (page: page, search: ''));
});
final jobProvider = FutureProvider.autoDispose.family<Json, String>((ref, id) {
  watchSession(ref);
  return ref.watch(platformRepositoryProvider).detail('prospecting-jobs', id);
});
final dashboardProvider =
    FutureProvider.autoDispose<({PageResult campaigns, PageResult prospects})>(
        (ref) async {
  watchSession(ref);
  final repo = ref.watch(platformRepositoryProvider);
  final results = await Future.wait([
    repo.list('campaigns', firstPage, limit: 6),
    repo.list('prospects', firstPage, limit: 1)
  ]);
  return (campaigns: results[0], prospects: results[1]);
});
