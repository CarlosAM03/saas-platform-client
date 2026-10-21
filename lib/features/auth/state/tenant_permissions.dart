import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import 'auth_state.dart';

typedef SessionScope = ({String userId, String? tenantId, Object session});

/// A loading/expired/logged-out session has no readable feature state.
final sessionScopeProvider = Provider<SessionScope?>((ref) {
  final auth = ref.watch(authControllerProvider);
  final context = auth.context;
  if (auth.status != AuthStatus.authenticated || context == null) return null;
  return (
    userId: context.user.id,
    tenantId: context.currentTenantId,
    session: context
  );
});

class TenantPermissions {
  const TenantPermissions(
      {this.admin = false, this.role, this.hasTenant = false});
  final bool admin, hasTenant;
  final RoleName? role;
  bool get canRead => hasTenant && (admin || role != null);
  bool get canManageCampaigns => canRead;
  bool get canEditProspects => canRead;
  bool get canCreateProspects => hasTenant && (admin || role == RoleName.OWNER);
  bool get canManageUsers => canCreateProspects;
  bool get canDeactivateUsers => hasTenant && admin;
  bool get canCreateTenants => admin;
  bool get canDeleteCampaigns => hasTenant && admin;
  String get label => admin ? 'ADMIN' : role?.name ?? 'Sin rol de organización';
}

final currentTenantPermissionsProvider =
    FutureProvider.autoDispose<TenantPermissions>((ref) async {
  final scope = ref.watch(sessionScopeProvider);
  final context = ref.watch(authControllerProvider).context;
  if (scope == null || context == null) return const TenantPermissions();
  if (context.user.platformRole == 'ADMIN') {
    return TenantPermissions(admin: true, hasTenant: scope.tenantId != null);
  }
  if (scope.tenantId == null) return const TenantPermissions();
  final user = await ref.watch(platformApiProvider).users.get(scope.userId);
  // Fail closed if the returned role belongs to another tenant.
  final role = user.role?.tenantId == scope.tenantId ? user.role?.name : null;
  return TenantPermissions(role: role, hasTenant: true);
});
