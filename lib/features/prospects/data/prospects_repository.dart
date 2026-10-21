import '../../../platform_api/platform_api.dart';

abstract interface class ProspectsRepository {
  Future<PaginatedResult<Prospect>> list(
      {PaginationQuery query = const PaginationQuery()});
  Future<Prospect> get(String id);
  Future<Prospect> create(CreateProspectRequest request);
  Future<Prospect> update(String id, UpdateProspectRequest request);
}

class ApiProspectsRepository implements ProspectsRepository {
  ApiProspectsRepository(PlatformApi api) : _api = api.prospects;
  final ProspectsApi _api;
  @override
  Future<PaginatedResult<Prospect>> list(
          {PaginationQuery query = const PaginationQuery()}) =>
      _api.list(query: query);
  @override
  Future<Prospect> get(String id) => _api.get(id);
  @override
  Future<Prospect> create(CreateProspectRequest request) =>
      _api.create(request);
  @override
  Future<Prospect> update(String id, UpdateProspectRequest request) =>
      _api.update(id, request);
}
