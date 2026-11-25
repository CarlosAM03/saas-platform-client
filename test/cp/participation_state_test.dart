import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaign_prospects_panel.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaigns_page.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/campaigns/state/participation_providers.dart';
import 'package:saas_platform_client/platform_api/campaign_participation_api.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../features/feature_fixtures.dart';
import '../features/campaigns_fixtures.dart';
import 'cp_fixtures.dart';

void main() {
  testWidgets('commercial summary opens page one with the selected filter', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeParticipation();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
          participationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CampaignDetailPage(entityId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, false);
    await tester.tap(find.text('Prospectos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(repository.lastQuery?.page, 2);

    for (final (action, filter, chip) in [
      ('Sin gestionar', {'stage': 'SIN_GESTIONAR'}, 'Sin gestionar'),
      (
        'Asignar responsables',
        {'responsibleId': 'UNASSIGNED'},
        'Sin responsable',
      ),
      (
        'Revisar prospectos sin evaluar',
        {'evaluation': 'SIN_EVALUAR'},
        'Sin evaluar',
      ),
    ]) {
      await tester.tap(find.text('Resumen comercial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(repository.lastQuery?.page, 1);
      expect(repository.lastFilters?.toQuery(), filter);
      expect(find.widgetWithText(Chip, chip), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Quitar filtro de evaluación'));
    await tester.pumpAndSettle();
    expect(repository.lastFilters?.toQuery(), isEmpty);

    await tester.tap(find.text('Resumen comercial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar prospectos sin evaluar'));
    await tester.pumpAndSettle();
    expect(repository.lastQuery?.page, 1);
    expect(repository.lastFilters?.toQuery(), {'evaluation': 'SIN_EVALUAR'});
    expect(find.widgetWithText(Chip, 'Sin evaluar'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, true);
    await tester.tap(find.text('Resumen comercial'));
    await tester.pumpAndSettle();
    expect(find.text('Etapas comerciales'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'CP discards a late response and reloads on tenant replacement',
    () async {
      final pending = Completer<PaginatedResult<CampaignProspect>>();
      final repo = FakeParticipation()..pending = pending.future;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          participationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      const key = (
        campaign: 'c',
        query: PaginationQuery(page: 1),
        filters: CampaignProspectFilters(),
      );
      final sub = container.listen(
        filteredCampaignProspectsProvider(key),
        (_, __) {},
      );
      addTearDown(sub.close);
      expect(
        container.read(filteredCampaignProspectsProvider(key)).isLoading,
        true,
      );
      await container.pump();
      repo.pending = null;
      (container.read(authControllerProvider.notifier) as FeatureAuthController)
          .setSession(session(tenant: 'b'));
      await container.pump();
      final fresh = await container.read(
        filteredCampaignProspectsProvider(key).future,
      );
      expect(fresh.items, hasLength(1));
      pending.complete(
        const PaginatedResult(
          items: [],
          meta: PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 0),
        ),
      );
      await container.pump();
      expect(
        container
            .read(filteredCampaignProspectsProvider(key))
            .requireValue
            .items,
        hasLength(1),
      );
      expect(repo.reads, 2);
    },
  );
  for (final role in RoleName.values) {
    testWidgets('CP filters, pagination and $role creation visibility', (
      tester,
    ) async {
      final repo = FakeParticipation();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            participationRepositoryProvider.overrideWithValue(repo),
            currentTenantPermissionsProvider.overrideWith(
              (ref) async => TenantPermissions(role: role, hasTenant: true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CampaignProspectsPanel('c')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Business'), findsOneWidget);
      expect(
        find.text('Nuevo prospecto'),
        role == RoleName.OWNER ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Importar CSV'),
        role == RoleName.OWNER ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Página 2 · 21 registros'), findsOneWidget);
      await tester.tap(find.text('Filtrar prospectos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sin asignar'));
      await tester.tap(find.text('Sin asignar'));
      await tester.pumpAndSettle();
      expect(find.text('Filtros activos: 1'), findsOneWidget);
      expect(find.text('Página 1 · 21 registros'), findsOneWidget);
    });
  }
  testWidgets('CP shows the original validation error and retries', (
    tester,
  ) async {
    final repo = FakeParticipation()
      ..error = const ApiException(
        kind: ApiErrorKind.badRequest,
        code: 'VALIDATION_ERROR',
        message: 'Date requires a timezone',
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          participationRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CampaignProspectsPanel('c')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('VALIDATION_ERROR: Date requires a timezone'),
      findsOneWidget,
    );
    repo.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsOneWidget);
  });
}
