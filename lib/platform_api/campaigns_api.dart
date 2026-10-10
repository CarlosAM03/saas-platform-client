import '../core/network/api_client.dart';
import '../shared/models/api_models.dart'
    show unwrapObject, unwrapPaginated, PaginatedResult;
import 'models.dart';
import 'requests.dart';
import 'pagination_query.dart';
import 'src/api_support.dart';

class CampaignsApi {
  const CampaignsApi(this._client);
  final ApiClient _client;
  Future<PaginatedResult<Campaign>> list(
          {PaginationQuery query = const PaginationQuery()}) async =>
      unwrapPaginated(
          await _client.get('/api/v1/campaigns',
              queryParameters: query.toQuery(allowedSorts: campaignSorts)),
          Campaign.fromJson);
  Future<Campaign> get(String id) async => Campaign.fromJson(
      unwrapObject(await _client.get(entityPath('campaigns', id))));
  Future<Campaign> create(CreateCampaignRequest request) async =>
      Campaign.fromJson(unwrapObject(
          await _client.post('/api/v1/campaigns', data: request.toJson())));
  Future<Campaign> update(String id, UpdateCampaignRequest request) async =>
      Campaign.fromJson(unwrapObject(await _client
          .patch(entityPath('campaigns', id), data: request.toJson())));

  Future<void> archive(String id) async =>
      parseEmpty(await _client.delete(entityPath('campaigns', id)));
  Future<void> deletePermanently(String id) async =>
      parseEmpty(await _client.delete(entityPath('campaigns', id),
          queryParameters: {'permanent': true}));
  Future<PaginatedResult<Prospect>> prospects(String id,
          {PaginationQuery query = const PaginationQuery()}) async =>
      unwrapPaginated(
          await _client.get('${entityPath('campaigns', id)}/prospects',
              queryParameters: query.toQuery(allowedSorts: commonSorts)),
          Prospect.fromJson);
}
