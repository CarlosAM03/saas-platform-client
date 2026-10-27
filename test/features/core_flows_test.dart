import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/routes/app_router.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/users/presentation/users_pages.dart';
import 'package:saas_platform_client/features/users/state/users_providers.dart';
import 'package:saas_platform_client/features/campaigns/presentation/campaigns_page.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospects_page.dart';
import 'package:saas_platform_client/features/prospects/state/prospects_providers.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'package:saas_platform_client/features/tenants/presentation/tenants_pages.dart';
import 'feature_fixtures.dart';
import 'users_fixtures.dart';
import 'campaigns_fixtures.dart';
import 'prospects_fixtures.dart';
import 'tenants_fixtures.dart';

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Guardar'));
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  test('tenant switching keeps selector mounted with prior context', () {
    final switching = AuthState(status: AuthStatus.loading, context: session());
    expect(redirectForAuth(switching, '/change-tenant'), isNull);
  });
  for (final path in [
    '/users',
    '/users/new',
    '/users/$entityId',
    '/users/$entityId/edit',
    '/campaigns/new',
    '/campaigns/$entityId',
    '/campaigns/$entityId/edit',
    '/prospects/new',
    '/prospects/$entityId',
    '/prospects/$entityId/edit',
  ]) {
    test('routing guards $path without loops', () {
      expect(
        redirectForAuth(
          const AuthState(status: AuthStatus.unauthenticated),
          path,
        ),
        '/login',
      );
      expect(
        redirectForAuth(
          const AuthState(status: AuthStatus.sessionExpired),
          path,
        ),
        '/session-expired',
      );
      expect(
        redirectForAuth(
          const AuthState(status: AuthStatus.backendUnavailable),
          path,
        ),
        '/backend-unavailable',
      );
      final noTenant = AuthState(
        status: AuthStatus.authenticated,
        context: session(tenant: null, platformRole: 'ADMIN'),
      );
      expect(redirectForAuth(noTenant, path), '/select-tenant');
      expect(redirectForAuth(noTenant, '/select-tenant'), isNull);
      expect(
        redirectForAuth(
          AuthState(status: AuthStatus.authenticated, context: session()),
          path,
        ),
        isNull,
      );
    });
  }
  testWidgets(
    'all CRUD routes and mobile layouts render; router survives context changes',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          tenantsRepositoryProvider.overrideWithValue(FakeTenants()),
          usersRepositoryProvider.overrideWithValue(FakeUsers()),
          campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
          prospectsRepositoryProvider.overrideWithValue(FakeProspects()),
          dashboardProvider.overrideWith(
            (ref) async => DashboardData(
              campaigns: PaginatedResult(
                items: [],
                meta: const PaginationMeta(
                  page: 1,
                  limit: 5,
                  total: 0,
                  totalPages: 0,
                ),
              ),
              prospects: PaginatedResult(
                items: [],
                meta: const PaginationMeta(
                  page: 1,
                  limit: 5,
                  total: 0,
                  totalPages: 0,
                ),
              ),
              jobs: PaginatedResult(
                items: [],
                meta: const PaginationMeta(
                  page: 1,
                  limit: 5,
                  total: 0,
                  totalPages: 0,
                ),
              ),
            ),
          ),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(admin: true, hasTenant: true),
          ),
        ],
      );
      addTearDown(c.dispose);
      final router = c.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      for (final path in [
        '/tenants',
        '/tenants/new',
        '/tenants/$entityId',
        '/users',
        '/users/new',
        '/users/$entityId',
        '/users/$entityId/edit',
        '/campaigns',
        '/campaigns/new',
        '/campaigns/$entityId',
        '/campaigns/$entityId/edit',
        '/prospects',
        '/prospects/new',
        '/prospects/$entityId',
        '/prospects/$entityId/edit',
        '/profile',
        '/admin',
        '/change-tenant',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, path);
        expect(tester.takeException(), isNull, reason: path);
        if (path == '/campaigns/$entityId') {
          await tester.tap(find.text('Prospectos').last);
          await tester.pumpAndSettle();
          expect(find.text('Business'), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'mobile campaign prospects tab',
          );
        }
      }
      router.go('/users/new');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Tenant A draft',
      );
      (c.read(authControllerProvider.notifier) as FeatureAuthController)
          .setSession(session(tenant: 'b'));
      await tester.pumpAndSettle();
      expect(identical(c.read(appRouterProvider), router), isTrue);
      expect(find.text('Tenant A draft'), findsNothing);
      (c.read(authControllerProvider.notifier) as FeatureAuthController)
          .setStatus(AuthStatus.sessionExpired);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/session-expired',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('campaign create sends real fields and navigates to detail', (
    tester,
  ) async {
    final repo = FakeCampaigns();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: CampaignFormPage()),
        ),
        GoRoute(
          path: '/campaigns/:id',
          builder: (_, __) => const Scaffold(body: Text('saved')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          campaignsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.MEMBER, hasTenant: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Campaign A');
    await tester.enterText(find.byType(TextFormField).at(1), 'Description');
    await save(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(repo.payload, {'name': 'Campaign A', 'description': 'Description'});
    expect(find.text('saved'), findsOneWidget);
  });
  testWidgets('campaign edit preserves unchanged nullable description', (
    tester,
  ) async {
    final repo = FakeCampaigns();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(body: CampaignFormPage(id: entityId)),
        ),
        GoRoute(
          path: '/campaigns/:id',
          builder: (_, __) => const Scaffold(body: Text('saved')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          campaignsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.MEMBER, hasTenant: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await save(tester);
    expect(repo.updates, 1);
    expect(repo.payload!.containsKey('description'), isFalse);
    expect(repo.payload!['name'], 'Renamed');
  });
  testWidgets('user update does not preload or send an unchanged password', (
    tester,
  ) async {
    final repo = FakeUsers();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: UserFormPage(id: entityId)),
        ),
        GoRoute(
          path: '/users/:id',
          builder: (_, __) => const Scaffold(body: Text('saved')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          usersRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.OWNER, hasTenant: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(2))
          .initialValue,
      '',
    );
    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await save(tester);
    expect(repo.updates, 1);
    expect(repo.payload!.containsKey('password'), isFalse);
    expect(repo.payload!.containsKey('roleId'), isFalse);
  });
  testWidgets('manual create selects a campaign from the paged API list', (
    tester,
  ) async {
    final repo = FakeProspects();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: ProspectFormPage()),
        ),
        GoRoute(
          path: '/prospects/:id',
          builder: (_, __) => const Scaffold(body: Text('saved')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          prospectsRepositoryProvider.overrideWithValue(repo),
          campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.OWNER, hasTenant: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar campaña'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campaign'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Manual A');
    await save(tester);
    expect(repo.creates, 1);
    expect(repo.payload, {
      'campaignId': entityId,
      'name': 'Manual A',
      'status': 'ACTIVO',
    });
    expect(find.text('saved'), findsOneWidget);
  });
  testWidgets('prospect edit clears only changed nullable field', (
    tester,
  ) async {
    final repo = FakeProspects()
      ..detail = Prospect.fromJson({
        ...prospectJson,
        'phone': '123',
        'metadata': {'keep': true},
      });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(body: ProspectFormPage(id: entityId)),
        ),
        GoRoute(
          path: '/prospects/:id',
          builder: (_, __) => const Scaffold(body: Text('saved')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          prospectsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.MEMBER, hasTenant: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(3), '');
    await save(tester);
    expect(repo.payload, {'phone': null});
    expect(find.text('saved'), findsOneWidget);
  });
  testWidgets('tenant create and detail use the repository', (tester) async {
    final repo = FakeTenants();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: TenantCreatePage()),
        ),
        GoRoute(
          path: '/tenants/:id',
          builder: (_, s) =>
              Scaffold(body: TenantDetailPage(s.pathParameters['id']!)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          tenantsRepositoryProvider.overrideWithValue(repo),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async => const TenantPermissions(admin: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'New organization',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'new-org');
    await save(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/tenants/$entityId',
    );
    expect(find.text('Usar organización'), findsOneWidget);
  });
}
