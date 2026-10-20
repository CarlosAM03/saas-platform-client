import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../data/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final scope = ref.watch(sessionScopeProvider);
  if (scope?.tenantId == null) {
    throw StateError('A selected tenant is required');
  }
  return ApiUsersRepository(ref.watch(platformApiProvider));
});
final usersListProvider = FutureProvider.autoDispose
    .family<PaginatedResult<User>, PageKey>((ref, key) {
  ref.watch(sessionScopeProvider);
  return ref.watch(usersRepositoryProvider).list(query: pageQuery(key));
});
final usersDetailProvider =
    FutureProvider.autoDispose.family<User, String>((ref, id) {
  ref.watch(sessionScopeProvider);
  return ref.watch(usersRepositoryProvider).get(id);
});
