import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../auth/state/tenant_permissions.dart';
import '../data/dashboard_repository.dart';
export '../data/dashboard_repository.dart';

final dashboardRepositoryProvider =
    Provider.autoDispose<DashboardRepository>((ref) {
  if (ref.watch(sessionScopeProvider)?.tenantId == null) {
    throw StateError('Selecciona una organización');
  }
  return ApiDashboardRepository(ref.watch(platformApiProvider));
});
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  ref.watch(sessionScopeProvider);
  final permissions = await ref.watch(currentTenantPermissionsProvider.future);
  return ref
      .watch(dashboardRepositoryProvider)
      .load(includeProspecting: permissions.canCreateProspects);
});
