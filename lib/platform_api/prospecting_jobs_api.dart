import '../core/network/api_client.dart';
import '../core/network/api_download.dart';
import '../shared/models/api_models.dart'
    show unwrapObject, unwrapPaginated, PaginatedResult;
import 'models.dart';
import 'requests.dart';
import 'pagination_query.dart';
import 'src/api_support.dart';

class ProspectingJobsApi {
  const ProspectingJobsApi(this._client);
  final ApiClient _client;
  Future<PaginatedResult<ProspectingJobSummary>> list(
          {PaginationQuery query = const PaginationQuery()}) async =>
      unwrapPaginated(
          await _client.get('/api/v1/prospecting-jobs',
              queryParameters:
                  query.toQuery(allowedSorts: jobSorts, allowSearch: false)),
          ProspectingJobSummary.fromJson);
  Future<ProspectingJobDetail> get(String id) async =>
      ProspectingJobDetail.fromJson(
          unwrapObject(await _client.get(entityPath('prospecting-jobs', id))));
  // Current backend returns 503 / error.details.reason=PROSPECTOR_INTEGRATION_PENDING.
  Future<ProspectingJobDetail> create(CreateProspectingJobRequest request,
      {required String idempotencyKey}) async {
    if (idempotencyKey.trim().isEmpty) {
      throw ArgumentError('Idempotency-Key is required');
    }
    return ProspectingJobDetail.fromJson(unwrapObject(await _client.post(
        '/api/v1/prospecting-jobs',
        data: request.toJson(),
        headers: {'Idempotency-Key': idempotencyKey})));
  }

  Future<ProspectingJobDetail> cancel(String id) async =>
      ProspectingJobDetail.fromJson(unwrapObject(
          await _client.post('${entityPath('prospecting-jobs', id)}/cancel')));
  Future<PersistResultsResult> persist(String id) async =>
      PersistResultsResult.fromJson(unwrapObject(
          await _client.post('${entityPath('prospecting-jobs', id)}/persist')));
  Future<ApiDownload> export(String id, {required ExportFormat format}) =>
      _client.downloadBytes('${entityPath('prospecting-jobs', id)}/export',
          queryParameters: {'format': format.name});
}
