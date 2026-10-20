import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/prospects/data/prospects_repository.dart';
import 'package:saas_platform_client/features/prospects/state/prospects_providers.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospects_page.dart';
import 'feature_fixtures.dart';
import 'prospects_fixtures.dart';

const key = (page: 1, search: '', sort: SortField.name, order: SortOrder.asc);
void main() {
  test('prospects API repository uses typed requests and queries', () async {
    final adapter = ContractAdapter()..response = page(prospectJson);
    final repo = ApiProspectsRepository(testApi(adapter));
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
    adapter.response = envelope(prospectJson);
    expect((await repo.get(entityId)).id, entityId);
    await repo
        .create(const CreateProspectRequest(campaignId: entityId, name: 'A'));
    expect(adapter.request!.method, 'POST');
    await repo.update(entityId, const UpdateProspectRequest(name: 'Updated'));
    expect(adapter.request!.method, 'PATCH');
  });
  test('prospects providers drop old tenant state and ignore a late response',
      () async {
    final old = Completer<PaginatedResult<Prospect>>();
    final repo = FakeProspects()..pending = old.future;
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(FeatureAuthController.new),
      prospectsRepositoryProvider.overrideWithValue(repo)
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(prospectsListProvider(key), (_, __) {});
    addTearDown(sub.close);
    expect(c.read(prospectsListProvider(key)).isLoading, isTrue);
    // Repository overrides deliberately survive the switch; the future must still reload.
    repo.pending = null;
    repo.items = [];
    await c.read(authControllerProvider.notifier).selectTenant('b');
    final current = await c.read(prospectsListProvider(key).future);
    expect(current.items, isEmpty);
    old.complete(PaginatedResult(
        items: [Prospect.fromJson(prospectJson)],
        meta:
            const PaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1)));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(prospectsListProvider(key)).asData!.value.items, isEmpty);
  });
  for (final mode in ['loading', 'empty', 'error', 'success']) {
    testWidgets('prospects list $mode', (tester) async {
      final repo = FakeProspects();
      if (mode == 'loading')
        repo.pending = Completer<PaginatedResult<Prospect>>().future;
      if (mode == 'empty') repo.items = [];
      if (mode == 'error')
        repo.error =
            const ApiException(kind: ApiErrorKind.forbidden, message: 'denied');
      await tester.pumpWidget(ProviderScope(overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        prospectsRepositoryProvider.overrideWithValue(repo),
        currentTenantPermissionsProvider.overrideWith((ref) async =>
            const TenantPermissions(role: RoleName.OWNER, hasTenant: true))
      ], child: const MaterialApp(home: Scaffold(body: ProspectsPage()))));
      await tester.pump();
      if (mode == 'loading')
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      if (mode == 'empty')
        expect(find.text('No hay información disponible.'), findsOneWidget);
      if (mode == 'error')
        expect(find.text('No tienes permisos para realizar esta acción.'),
            findsOneWidget);
      if (mode == 'success') {
        expect(find.text('Business'), findsOneWidget);
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
  testWidgets('prospects detail and edit visibility for MEMBER',
      (tester) async {
    final repo = FakeProspects();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          prospectsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith((ref) async =>
              const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
        ],
        child: const MaterialApp(
            home: Scaffold(body: ProspectDetailPage(entityId)))));
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Editar prospecto'), findsOneWidget);
  });
  testWidgets('prospects direct create route permission', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      currentTenantPermissionsProvider.overrideWith((ref) async =>
          const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
    ], child: const MaterialApp(home: Scaffold(body: ProspectFormPage()))));
    await tester.pumpAndSettle();
    expect(find.text('No tienes permisos para realizar esta acción.'),
        findsOneWidget);
  });
  test('prospect edit preserves omission and explicit clearing', () {
    final p = Prospect.fromJson({
      ...prospectJson,
      'phone': '123',
      'metadata': {'keep': true}
    });
    final values = {
      for (final e in prospectTextValues(p).entries) e.key: e.value ?? '',
      'name': p.name,
      'status': p.status.name
    };
    values['phone'] = '';
    values['name'] = 'Edited';
    expect(
        prospectUpdate(p, values).toJson(), {'name': 'Edited', 'phone': null});
  });
  for (final source in ['google_maps', 'manual', 'csv']) {
    testWidgets('source badge $source', (tester) async {
      final repo = FakeProspects()
        ..items = [
          Prospect.fromJson({...prospectJson, 'source': source})
        ];
      await tester.pumpWidget(ProviderScope(overrides: [
        prospectsRepositoryProvider.overrideWithValue(repo),
        currentTenantPermissionsProvider.overrideWith((ref) async =>
            const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
      ], child: const MaterialApp(home: Scaffold(body: ProspectsPage()))));
      await tester.pumpAndSettle();
      expect(find.text(source), findsOneWidget);
      expect(find.text('Crear prospecto'), findsNothing);
    });
  }
}
