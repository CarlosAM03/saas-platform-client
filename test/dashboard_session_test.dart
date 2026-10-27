import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'features/feature_fixtures.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';

DashboardData data(int total) {
  PaginatedResult<T> page<T>() => PaginatedResult<T>(
    items: [],
    meta: PaginationMeta(page: 1, limit: 5, total: total, totalPages: 1),
  );
  return DashboardData(
    campaigns: page<Campaign>(),
    prospects: page<Prospect>(),
    jobs: page<ProspectingJobSummary>(),
  );
}

class DeferredDashboard implements DashboardRepository {
  final previous = Completer<DashboardData>();
  int reads = 0;
  @override
  Future<DashboardData> load() =>
      ++reads == 1 ? previous.future : Future.value(data(2));
}

void main() {
  test(
    'late dashboard response cannot repopulate another tenant or logout',
    () async {
      final repository = DeferredDashboard();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          dashboardRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(dashboardProvider, (_, __) {});
      addTearDown(subscription.close);
      expect(container.read(dashboardProvider).isLoading, isTrue);
      await container.read(authControllerProvider.notifier).selectTenant('b');
      expect(
        (await container.read(dashboardProvider.future)).campaigns.meta.total,
        2,
      );
      repository.previous.complete(data(99));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(dashboardProvider).asData!.value.campaigns.meta.total,
        2,
      );
      (container.read(authControllerProvider.notifier) as FeatureAuthController)
          .setStatus(AuthStatus.unauthenticated);
      expect(container.read(dashboardProvider).isLoading, isTrue);
      expect(container.read(dashboardProvider).asData, isNull);
    },
  );
}
