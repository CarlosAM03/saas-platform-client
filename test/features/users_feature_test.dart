import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/users/data/users_repository.dart';
import 'package:saas_platform_client/features/users/state/users_providers.dart';
import 'package:saas_platform_client/features/users/presentation/users_pages.dart';
import 'feature_fixtures.dart';
import 'users_fixtures.dart';

const key = (page: 1, search: '', sort: SortField.name, order: SortOrder.asc);
void main() {
  test('users API repository uses typed requests and queries', () async {
    final adapter = ContractAdapter()..response = page(userJson);
    final repo = ApiUsersRepository(testApi(adapter));
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
    adapter.response = envelope(userJson);
    expect((await repo.get(entityId)).id, entityId);
    await repo.create(const CreateUserRequest(
        name: 'A', email: 'a@example.com', password: 'Password123!'));
    expect(adapter.request!.method, 'POST');
    await repo.update(entityId, const UpdateUserRequest(name: 'Updated'));
    expect(adapter.request!.method, 'PATCH');
    adapter.response = envelope({});
    await repo.deactivate(entityId);
    expect(adapter.request!.method, 'DELETE');
  });
  test('users providers drop old tenant state and ignore a late response',
      () async {
    final old = Completer<PaginatedResult<User>>();
    final repo = FakeUsers()..pending = old.future;
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(FeatureAuthController.new),
      usersRepositoryProvider.overrideWithValue(repo)
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(usersListProvider(key), (_, __) {});
    addTearDown(sub.close);
    expect(c.read(usersListProvider(key)).isLoading, isTrue);
    // Repository overrides deliberately survive the switch; the future must still reload.
    repo.pending = null;
    repo.items = [];
    await c.read(authControllerProvider.notifier).selectTenant('b');
    final current = await c.read(usersListProvider(key).future);
    expect(current.items, isEmpty);
    old.complete(PaginatedResult(
        items: [User.fromJson(userJson)],
        meta:
            const PaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1)));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(usersListProvider(key)).asData!.value.items, isEmpty);
  });
  for (final mode in ['loading', 'empty', 'error', 'success']) {
    testWidgets('users list $mode', (tester) async {
      final repo = FakeUsers();
      if (mode == 'loading') {
        repo.pending = Completer<PaginatedResult<User>>().future;
      }
      if (mode == 'empty') repo.items = [];
      if (mode == 'error') {
        repo.error =
            const ApiException(kind: ApiErrorKind.forbidden, message: 'denied');
      }
      await tester.pumpWidget(ProviderScope(overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        usersRepositoryProvider.overrideWithValue(repo),
        currentTenantPermissionsProvider.overrideWith((ref) async =>
            const TenantPermissions(role: RoleName.OWNER, hasTenant: true))
      ], child: const MaterialApp(home: Scaffold(body: UsersPage()))));
      await tester.pump();
      if (mode == 'loading') {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
      if (mode == 'empty') {
        expect(find.text('No hay información disponible.'), findsOneWidget);
      }
      if (mode == 'error') {
        expect(find.text('No tienes permisos para realizar esta acción.'),
            findsOneWidget);
      }
      if (mode == 'success') {
        expect(find.text('Owner'), findsOneWidget);
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
  testWidgets('users detail and edit visibility for MEMBER', (tester) async {
    final repo = FakeUsers();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          usersRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith((ref) async =>
              const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
        ],
        child:
            const MaterialApp(home: Scaffold(body: UserDetailPage(entityId)))));
    await tester.pumpAndSettle();
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Editar usuario'), findsNothing);
    expect(find.text('Desactivar usuario'), findsNothing);
  });
  testWidgets('users direct create route permission', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      currentTenantPermissionsProvider.overrideWith((ref) async =>
          const TenantPermissions(role: RoleName.MEMBER, hasTenant: true))
    ], child: const MaterialApp(home: Scaffold(body: UserFormPage()))));
    await tester.pumpAndSettle();
    expect(find.text('No tienes permisos para realizar esta acción.'),
        findsOneWidget);
  });
  testWidgets('create user omits roleId; update never preloads password',
      (tester) async {
    final repo = FakeUsers();
    final router = GoRouter(initialLocation: '/new', routes: [
      GoRoute(
          path: '/new',
          builder: (_, __) => const Scaffold(body: UserFormPage())),
      GoRoute(
          path: '/users/:id',
          builder: (_, __) => const Scaffold(body: Text('saved')))
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      usersRepositoryProvider.overrideWithValue(repo),
      currentTenantPermissionsProvider.overrideWith((ref) async =>
          const TenantPermissions(role: RoleName.OWNER, hasTenant: true))
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    expect(find.text('El usuario se crea como MEMBER'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'New User');
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.creates, 1);
    expect(repo.payload!.containsKey('roleId'), isFalse);
    expect(find.text('saved'), findsOneWidget);
  });
  testWidgets('deactivate is confirmed and invokes repository', (tester) async {
    final repo = FakeUsers();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          usersRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith((ref) async =>
              const TenantPermissions(admin: true, hasTenant: true))
        ],
        child:
            const MaterialApp(home: Scaffold(body: UserDetailPage(entityId)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar usuario'));
    await tester.pumpAndSettle();
    expect(repo.removals, 0);
    await tester.tap(find.text('Confirmar').last);
    await tester.pumpAndSettle();
    expect(repo.removals, 1);
  });
}
