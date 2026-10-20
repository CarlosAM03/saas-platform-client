import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/campaigns/data/campaigns_repository.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaigns_page.dart';
import 'feature_fixtures.dart';
import 'campaigns_fixtures.dart';

const key = (page: 1, search: '', sort: SortField.name, order: SortOrder.asc);
void main() {
  test('campaigns API repository uses typed requests and queries', () async {
    final adapter = ContractAdapter()..response = page(campaignJson);
    final repo = ApiCampaignsRepository(testApi(adapter));
    expect(
        (await repo.list(
                query: const PaginationQuery(
                    page: 2,
                    search: 'coffee',
                    sortBy: SortField.createdAt,
                    sortOrder: SortOrder.desc)))
            .items,
        hasLength(1));
    expect(adapter.request!.queryParameters, {
      'page': 2,
      'search': 'coffee',
      'sortBy': 'createdAt',
      'sortOrder': 'desc'
    });
    adapter.response = envelope(campaignJson);
    expect((await repo.get(entityId)).id, entityId);
    await repo.create(const CreateCampaignRequest(name: 'A'));
    expect(adapter.request!.method, 'POST');
    await repo.update(entityId, const UpdateCampaignRequest(name: 'Updated'));
    expect(adapter.request!.method, 'PATCH');
    adapter.response = envelope({});
    await repo.archive(entityId);
    expect(adapter.request!.queryParameters, isEmpty);
    await repo.deletePermanently(entityId);
    expect(adapter.request!.queryParameters, {'permanent': true});
    adapter.response = page(prospectJson);
    expect((await repo.prospects(entityId)).items.single.id, entityId);
  });
  test('campaigns providers drop old tenant state and ignore a late response',
      () async {
    final old = Completer<PaginatedResult<Campaign>>();
    final repo = FakeCampaigns()..pending = old.future;
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(FeatureAuthController.new),
      campaignsRepositoryProvider.overrideWithValue(repo)
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(campaignsListProvider(key), (_, __) {});
    addTearDown(sub.close);
    expect(c.read(campaignsListProvider(key)).isLoading, isTrue);
    // Repository overrides deliberately survive the switch; the future must still reload.
    repo.pending = null;
    repo.items = [];
    await c.read(authControllerProvider.notifier).selectTenant('b');
    final current = await c.read(campaignsListProvider(key).future);
    expect(current.items, isEmpty);
    old.complete(PaginatedResult(
        items: [Campaign.fromJson(campaignJson)],
        meta:
            const PaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1)));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(campaignsListProvider(key)).asData!.value.items, isEmpty);
  });
  for (final mode in ['loading', 'empty', 'error', 'success']) {
    testWidgets('campaigns list $mode', (tester) async {
      final repo = FakeCampaigns();
      if (mode == 'loading')
        repo.pending = Completer<PaginatedResult<Campaign>>().future;
      if (mode == 'empty') repo.items = [];
      if (mode == 'error')
        repo.error =
            const ApiException(kind: ApiErrorKind.forbidden, message: 'denied');
      await tester.pumpWidget(ProviderScope(overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        campaignsRepositoryProvider.overrideWithValue(repo),
        currentTenantPermissionsProvider.overrideWith((ref) async =>
            const TenantPermissions(role: RoleName.OWNER, hasTenant: true))
      ], child: const MaterialApp(home: Scaffold(body: CampaignsPage()))));
      await tester.pump();
      if (mode == 'loading')
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      if (mode == 'empty')
        expect(find.text('No hay información disponible.'), findsOneWidget);
      if (mode == 'error')
        expect(find.text('No tienes permisos para realizar esta acción.'),
            findsOneWidget);
      if (mode == 'success') {
        expect(find.text('Campaign'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'coffee');
        await tester.tap(find.byTooltip('Buscar'));
        await tester.pumpAndSettle();
        expect(repo.lastQuery!.search, 'coffee');
        await tester.tap(find.byTooltip('Página siguiente'));
        await tester.pumpAndSettle();
        expect(repo.lastQuery!.page, 2);
        await tester.tap(find.byTooltip('Cambiar orden'));
        await tester.pumpAndSettle();
        expect(repo.lastQuery!.sortOrder, SortOrder.desc);
        expect(repo.lastQuery!.page, 1);
      }
    });
  }
  testWidgets('campaigns detail and edit visibility for MEMBER',
      (tester) async {
    final repo = FakeCampaigns();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          campaignsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith((ref) async =>
              const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
        ],
        child: const MaterialApp(
            home: Scaffold(body: CampaignDetailPage(entityId)))));
    await tester.pumpAndSettle();
    expect(find.text('Campaign'), findsOneWidget);
    expect(find.text('Editar campaña'), findsOneWidget);
    expect(find.text('Eliminar permanentemente'), findsNothing);
  });
  testWidgets('campaigns direct create route permission', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      currentTenantPermissionsProvider.overrideWith((ref) async =>
          const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
    ], child: const MaterialApp(home: Scaffold(body: CampaignFormPage()))));
    await tester.pumpAndSettle();
    expect(find.text('Guardar'), findsOneWidget);
  });
  testWidgets('permanent delete preserves 409 and does not navigate',
      (tester) async {
    final repo = FakeCampaigns();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          campaignsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith((ref) async =>
              const TenantPermissions(admin: true, hasTenant: true))
        ],
        child: const MaterialApp(
            home: Scaffold(body: CampaignDetailPage(entityId)))));
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsOneWidget);
    repo.error =
        const ApiException(kind: ApiErrorKind.conflict, message: 'dependent');
    await tester.tap(find.text('Eliminar permanentemente'));
    await tester.pumpAndSettle();
    expect(repo.removals, 0);
    await tester.tap(find.text('Confirmar').last);
    await tester.pumpAndSettle();
    expect(repo.removals, 1);
    expect(find.text('La operación entra en conflicto con el estado actual.'),
        findsOneWidget);
    expect(find.text('Campaign'), findsOneWidget);
  });
  testWidgets('MEMBER can create and archive campaigns', (tester) async {
    final repo = FakeCampaigns();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          campaignsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith((ref) async =>
              const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
        ],
        child: const MaterialApp(
            home: Scaffold(body: CampaignDetailPage(entityId)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivar campaña'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar').last);
    await tester.pumpAndSettle();
    expect(repo.removals, 1);
  });
}
