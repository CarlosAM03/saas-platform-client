import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/campaigns/data/campaigns_repository.dart';
import 'feature_fixtures.dart';
class FakeCampaigns implements CampaignsRepository {
  int creates = 0, updates = 0, removals = 0;
  Object? error;
  Map<String, dynamic>? payload;
  PaginationQuery? lastQuery;
  Future<PaginatedResult<Campaign>>? pending;
  List<Campaign> items = [Campaign.fromJson(campaignJson)];
  Campaign get entity => Campaign.fromJson(campaignJson);
  @override
  Future<PaginatedResult<Campaign>> list(
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
  Future<Campaign> get(String id) async {
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<Campaign> create(CreateCampaignRequest request) async {
    creates++;
    payload = request.toJson();
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<Campaign> update(String id, UpdateCampaignRequest request) async {
    updates++;
    payload = request.toJson();
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<void> archive(String id) async {
    removals++;
    if (error != null) throw error!;
  }

  @override
  Future<void> deletePermanently(String id) async {
    removals++;
    if (error != null) throw error!;
  }

  @override
  Future<PaginatedResult<Prospect>> prospects(String id,
          {PaginationQuery query = const PaginationQuery()}) async =>
      PaginatedResult(
          items: [Prospect.fromJson(prospectJson)],
          meta: const PaginationMeta(
              page: 1, limit: 20, total: 1, totalPages: 1));
}

