import '../../../platform_api/platform_api.dart';

abstract interface class CampaignsRepository {
  Future<PaginatedResult<Campaign>> list(
      {PaginationQuery query = const PaginationQuery()});
  Future<Campaign> get(String id);
  Future<Campaign> create(CreateCampaignRequest request);
  Future<Campaign> update(String id, UpdateCampaignRequest request);
  Future<void> archive(String id);
  Future<void> deletePermanently(String id);
  Future<PaginatedResult<Prospect>> prospects(String id,
      {PaginationQuery query = const PaginationQuery()});
}

class ApiCampaignsRepository implements CampaignsRepository {
  ApiCampaignsRepository(PlatformApi api) : _api = api.campaigns;
  final CampaignsApi _api;
  @override
  Future<PaginatedResult<Campaign>> list(
          {PaginationQuery query = const PaginationQuery()}) =>
      _api.list(query: query);
  @override
  Future<Campaign> get(String id) => _api.get(id);
  @override
  Future<Campaign> create(CreateCampaignRequest request) =>
      _api.create(request);
  @override
  Future<Campaign> update(String id, UpdateCampaignRequest request) =>
      _api.update(id, request);
  @override
  Future<void> archive(String id) => _api.archive(id);
  @override
  Future<void> deletePermanently(String id) => _api.deletePermanently(id);
  @override
  Future<PaginatedResult<Prospect>> prospects(String id,
          {PaginationQuery query = const PaginationQuery()}) =>
      _api.prospects(id, query: query);
}
