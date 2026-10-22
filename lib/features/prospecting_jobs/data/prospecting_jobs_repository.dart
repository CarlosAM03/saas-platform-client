import '../../../platform_api/platform_api.dart';

abstract interface class ProspectingJobsRepository {
  Future<PaginatedResult<ProspectingJobSummary>> list(PaginationQuery query);
  Future<ProspectingJobDetail> get(String id);
  Future<ProspectingJobDetail> create(
      CreateProspectingJobRequest request, String key);
  Future<ProspectingJobDetail> cancel(String id);
  Future<PersistResultsResult> persist(String id);
  Future<ApiDownload> export(String id, ExportFormat format);
}

class ApiProspectingJobsRepository implements ProspectingJobsRepository {
  ApiProspectingJobsRepository(PlatformApi api) : _api = api.prospectingJobs;
  final ProspectingJobsApi _api;
  @override
  Future<PaginatedResult<ProspectingJobSummary>> list(PaginationQuery query) =>
      _api.list(query: query);
  @override
  Future<ProspectingJobDetail> get(String id) => _api.get(id);
  @override
  Future<ProspectingJobDetail> create(
          CreateProspectingJobRequest request, String key) =>
      _api.create(request, idempotencyKey: key);
  @override
  Future<ProspectingJobDetail> cancel(String id) => _api.cancel(id);
  @override
  Future<PersistResultsResult> persist(String id) => _api.persist(id);
  @override
  Future<ApiDownload> export(String id, ExportFormat format) =>
      _api.export(id, format: format);
}
