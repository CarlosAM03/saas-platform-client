import 'dart:convert';
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
    session: context,
  );
});

class TenantPermissions {
  const TenantPermissions({
    this.admin = false,
    this.role,
    this.hasTenant = false,
  });
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
      return permissionsForAuthenticatedContext(context);
    });

/// Presentation only: the server validates the signature and authorizes requests.
/// Reading these claims does not authenticate a token or grant server authority.
/// Owner-approved FE-03 exception: do not replace the snapshot with a live DB role.
TenantPermissions permissionsForAuthenticatedContext(AuthContext context) {
  try {
    final parts = context.accessToken.split('.');
    if (parts.length != 3 || parts.any((part) => part.isEmpty)) {
      return const TenantPermissions();
    }
    Object? decode(String value) =>
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(value))));
    final header = decode(parts[0]);
    final claims = decode(parts[1]);
    if (header is! Map ||
        header['alg'] != 'HS256' ||
        claims is! Map ||
        claims['sub'] != context.user.id ||
        claims['tenantId'] != context.currentTenantId ||
        claims['exp'] is! int ||
        (claims['exp'] as int) <=
            DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      return const TenantPermissions();
    }
    final hasTenant = context.currentTenantId != null;
    if (claims['platformRole'] == 'ADMIN' && claims['tenantRole'] == null) {
      return TenantPermissions(admin: true, hasTenant: hasTenant);
    }
    if (claims['platformRole'] != null || !hasTenant) {
      return const TenantPermissions();
    }
    final role = switch (claims['tenantRole']) {
      'OWNER' => RoleName.OWNER,
      'MEMBER' => RoleName.MEMBER,
      _ => null,
    };
    return TenantPermissions(role: role, hasTenant: hasTenant);
  } on FormatException {
    return const TenantPermissions();
  }
}
