import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/prospects/data/prospects_repository.dart';
import 'feature_fixtures.dart';
class FakeProspects implements ProspectsRepository {
  int creates = 0, updates = 0, removals = 0;
  Object? error;
  Map<String, dynamic>? payload;
  PaginationQuery? lastQuery;
  Future<PaginatedResult<Prospect>>? pending;
  List<Prospect> items = [Prospect.fromJson(prospectJson)];
  Prospect get entity => Prospect.fromJson(prospectJson);
  @override
  Future<PaginatedResult<Prospect>> list(
      {PaginationQuery query = const PaginationQuery()}) async {
    lastQuery = query;
    if (error != null) throw error!;
    if (pending != null) return pending!;
    return PaginatedResult(
        items: items,
        meta: PaginationMeta(
            page: query.page ?? 1, limit: 20, total: 40, totalPages: 2));
  }

  @override
  Future<Prospect> get(String id) async {
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<Prospect> create(CreateProspectRequest request) async {
    creates++;
    payload = request.toJson();
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<Prospect> update(String id, UpdateProspectRequest request) async {
    updates++;
    payload = request.toJson();
    if (error != null) throw error!;
    return entity;
  }
}
