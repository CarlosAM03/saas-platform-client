import '../../../platform_api/platform_api.dart';

abstract interface class UsersRepository {
  Future<PaginatedResult<User>> list(
      {PaginationQuery query = const PaginationQuery()});
  Future<User> get(String id);
  Future<User> create(CreateUserRequest request);
  Future<User> update(String id, UpdateUserRequest request);
  Future<void> deactivate(String id);
}

class ApiUsersRepository implements UsersRepository {
  ApiUsersRepository(PlatformApi api) : _api = api.users;
  final UsersApi _api;
  @override
  Future<PaginatedResult<User>> list(
          {PaginationQuery query = const PaginationQuery()}) =>
      _api.list(query: query);
  @override
  Future<User> get(String id) => _api.get(id);
  @override
  Future<User> create(CreateUserRequest request) => _api.create(request);
  @override
  Future<User> update(String id, UpdateUserRequest request) =>
      _api.update(id, request);
  @override
  Future<void> deactivate(String id) => _api.deactivate(id);
}
