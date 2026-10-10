import '../core/network/api_client.dart';
import '../shared/models/api_models.dart'
    show unwrapObject, unwrapPaginated, PaginatedResult;
import 'models.dart';
import 'requests.dart';
import 'pagination_query.dart';
import 'src/api_support.dart';

class UsersApi {
  const UsersApi(this._client);
  final ApiClient _client;
  Future<PaginatedResult<User>> list(
          {PaginationQuery query = const PaginationQuery()}) async =>
      unwrapPaginated(
          await _client.get('/api/v1/users',
              queryParameters: query.toQuery(allowedSorts: commonSorts)),
          User.fromJson);
  Future<User> get(String id) async =>
      User.fromJson(unwrapObject(await _client.get(entityPath('users', id))));
  Future<User> create(CreateUserRequest request) async =>
      User.fromJson(unwrapObject(
          await _client.post('/api/v1/users', data: request.toJson())));
  Future<User> update(String id, UpdateUserRequest request) async =>
      User.fromJson(unwrapObject(await _client.patch(entityPath('users', id),
          data: request.toJson())));
  Future<void> deactivate(String id) async =>
      parseEmpty(await _client.delete(entityPath('users', id)));
}
