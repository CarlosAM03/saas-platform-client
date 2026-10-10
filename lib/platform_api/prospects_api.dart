import '../core/network/api_client.dart';
import '../shared/models/api_models.dart'
    show unwrapObject, unwrapPaginated, PaginatedResult;
import 'models.dart';
import 'requests.dart';
import 'pagination_query.dart';
import 'src/api_support.dart';

class ProspectsApi {
  const ProspectsApi(this._client);
  final ApiClient _client;
  Future<PaginatedResult<Prospect>> list(
          {PaginationQuery query = const PaginationQuery()}) async =>
      unwrapPaginated(
          await _client.get('/api/v1/prospects',
              queryParameters: query.toQuery(allowedSorts: commonSorts)),
          Prospect.fromJson);
  Future<Prospect> get(String id) async => Prospect.fromJson(
      unwrapObject(await _client.get(entityPath('prospects', id))));

  Future<Prospect> update(String id, UpdateProspectRequest request) async =>
      Prospect.fromJson(unwrapObject(await _client
          .patch(entityPath('prospects', id), data: request.toJson())));

  Future<PaginatedResult<Prospect>> forCampaign(String campaignId,
          {PaginationQuery query = const PaginationQuery()}) async =>
      unwrapPaginated(
          await _client.get('${entityPath('campaigns', campaignId)}/prospects',
              queryParameters: query.toQuery(allowedSorts: commonSorts)),
          Prospect.fromJson);
}
