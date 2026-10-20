import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/users/data/users_repository.dart';
import 'feature_fixtures.dart';

class FakeUsers implements UsersRepository {
  int creates = 0, updates = 0, removals = 0;
  Object? error;
  Map<String, dynamic>? payload;
  PaginationQuery? lastQuery;
  Future<PaginatedResult<User>>? pending;
  List<User> items = [User.fromJson(userJson)];
  User get entity => User.fromJson(userJson);
  @override
  Future<PaginatedResult<User>> list(
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
  Future<User> get(String id) async {
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<User> create(CreateUserRequest request) async {
    creates++;
    payload = request.toJson();
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<User> update(String id, UpdateUserRequest request) async {
    updates++;
    payload = request.toJson();
    if (error != null) throw error!;
    return entity;
  }

  @override
  Future<void> deactivate(String id) async {
    removals++;
    if (error != null) throw error!;
  }
}
