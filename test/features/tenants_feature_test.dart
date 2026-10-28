import 'dart:async';
import 'tenants_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/tenants/data/tenants_repository.dart';
import 'package:saas_platform_client/features/tenants/state/tenants_providers.dart';
import 'package:saas_platform_client/features/tenants/presentation/tenants_pages.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'feature_fixtures.dart';

void main() {
  test(
    'Tenant API repository delegates list/detail/create/discovery',
    () async {
      final adapter = ContractAdapter()..response = envelope([tenantJson]);
      final repo = ApiTenantsRepository(testApi(adapter));
      expect((await repo.list()).single.name, 'Demo');
      expect((await repo.discover()).single.slug, 'demo');
      adapter.response = envelope(tenantJson);
      expect((await repo.get(entityId)).id, entityId);
      await repo.create(const CreateTenantRequest(name: 'Demo', slug: 'demo'));
      expect(adapter.request!.data, {'name': 'Demo', 'slug': 'demo'});
    },
  );
  test(
    'permissions resolve ADMIN, OWNER, MEMBER; fail closed for foreign tenant',
    () async {
      final adapter = ContractAdapter();
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          platformApiProvider.overrideWithValue(testApi(adapter)),
        ],
      );
      addTearDown(c.dispose);
      final auth =
          c.read(authControllerProvider.notifier) as FeatureAuthController;
      for (final role in RoleName.values) {
        adapter.response = envelope({
          ...userJson,
          'role': {...roleJson, 'tenantId': 'a', 'name': role.name},
        });
        auth.setSession(session(role: role));
        c.invalidate(currentTenantPermissionsProvider);
        final permissions = await c.read(
          currentTenantPermissionsProvider.future,
        );
        expect(permissions.canManageCampaigns, isTrue);
        expect(permissions.canEditProspects, isTrue);
        expect(permissions.canCreateProspects, role == RoleName.OWNER);
        expect(permissions.canManageUsers, role == RoleName.OWNER);
        expect(permissions.canDeactivateUsers, isFalse);
      }
      adapter.response = envelope({
        ...userJson,
        'role': {...roleJson, 'tenantId': 'foreign'},
      });
      auth.setSession(session(tokenTenant: 'foreign'));
      c.invalidate(currentTenantPermissionsProvider);
      expect(
        (await c.read(currentTenantPermissionsProvider.future)).canRead,
        isFalse,
      );
      auth.setSession(session(tenant: null, platformRole: 'ADMIN'));
      final admin = await c.read(currentTenantPermissionsProvider.future);
      expect(admin.canCreateTenants, isTrue);
      expect(admin.canManageUsers, isFalse);
      auth.setSession(session(platformRole: 'ADMIN'));
      expect(
        (await c.read(
          currentTenantPermissionsProvider.future,
        )).canDeactivateUsers,
        isTrue,
      );
      for (final status in [
        AuthStatus.loading,
        AuthStatus.sessionExpired,
        AuthStatus.unauthenticated,
      ]) {
        auth.setStatus(status);
        expect(c.read(sessionScopeProvider), isNull);
        expect(
          (await c.read(currentTenantPermissionsProvider.future)).canRead,
          isFalse,
        );
      }
    },
  );
  test('tenant providers reload on context switch', () async {
    final repo = FakeTenants();
    var calls = 0;
    repo.fetch = () async {
      calls++;
      return [];
    };
    final c = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        tenantsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(tenantsListProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(tenantsListProvider.future);
    await c.read(authControllerProvider.notifier).selectTenant('b');
    expect(c.read(tenantsListProvider).isLoading, isTrue);
    await c.read(tenantsListProvider.future);
    expect(calls, 2);
  });
  for (final mode in ['loading', 'empty', 'error', 'success']) {
    testWidgets('tenant list $mode', (tester) async {
      final repo = FakeTenants();
      if (mode == 'loading') {
        repo.fetch = () => Completer<List<Tenant>>().future;
      }
      if (mode == 'empty') repo.fetch = () async => [];
      if (mode == 'error') {
        repo.fetch = () async => throw const ApiException(
          kind: ApiErrorKind.forbidden,
          message: 'denied',
        );
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            tenantsRepositoryProvider.overrideWithValue(repo),
            currentTenantPermissionsProvider.overrideWith(
              (ref) async => const TenantPermissions(admin: true),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: TenantsPage())),
        ),
      );
      await tester.pump();
      if (mode == 'loading') {
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      }
      if (mode == 'empty') {
        expect(find.text('No hay organizaciones disponibles.'), findsOneWidget);
      }
      if (mode == 'error') {
        expect(
          find.text('No tienes permisos para realizar esta acción.'),
          findsOneWidget,
        );
      }
      if (mode == 'success') {
        expect(find.text('Demo'), findsOneWidget);
        expect(find.text('Crear organización'), findsOneWidget);
      }
    });
  }
  testWidgets('direct create route denies MEMBER', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.MEMBER, hasTenant: true),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: TenantCreatePage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No tienes permisos para realizar esta acción.'),
      findsOneWidget,
    );
    expect(find.text('Guardar'), findsNothing);
  });
}
