import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/presentation/auth_pages.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/users/presentation/users_pages.dart';
import 'package:saas_platform_client/features/users/state/users_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'features/feature_fixtures.dart';
import 'features/users_fixtures.dart';

AuthContext? fixtureContext;

class SprintAuth extends AuthController {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    context: fixtureContext ?? session(),
  );
}

String token(Map<String, Object?> changes) {
  String part(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': session().user.id, 'tenantId': 'a', 'tenantRole': 'OWNER', 'platformRole': null, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600, ...changes})}.synthetic-signature';
}

AuthContext contextWithToken(String value) => AuthContext(
  accessToken: value,
  user: session().user,
  tenants: session().tenants,
  currentTenantId: 'a',
);

void main() {
  tearDown(() => fixtureContext = null);
  for (final change in [
    'none',
    'name',
    'email',
    'password',
    'status',
    'trim',
  ]) {
    testWidgets('FE-01 differential user PATCH: $change', (tester) async {
      final repo = FakeUsers();
      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/edit',
            builder: (_, __) =>
                const Scaffold(body: UserFormPage(id: entityId)),
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
            authControllerProvider.overrideWith(SprintAuth.new),
            usersRepositoryProvider.overrideWithValue(repo),
            currentTenantPermissionsProvider.overrideWith(
              (ref) async => const TenantPermissions(
                role: RoleName.OWNER,
                hasTenant: true,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (change == 'name') await tester.enterText(fields.at(0), 'New name');
      if (change == 'email') {
        await tester.enterText(fields.at(1), 'new@example.invalid');
      }
      if (change == 'password') {
        await tester.enterText(fields.at(2), 'Synthetic123!');
      }
      if (change == 'trim') {
        await tester.enterText(fields.at(0), '  ${repo.entity.name}  ');
      }
      if (change == 'status') {
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('INACTIVO').last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      if (change == 'none' || change == 'trim') {
        expect(
          repo.updates,
          0,
          reason: 'Shared identity no-op must not send global fields',
        );
      } else {
        expect(repo.updates, 1);
        expect(repo.payload, switch (change) {
          'name' => {'name': 'New name'},
          'email' => {'email': 'new@example.invalid'},
          'password' => {'password': 'Synthetic123!'},
          _ => {'status': 'INACTIVO'},
        });
      }
      expect(find.text('saved'), findsOneWidget);
    });
  }
  for (final role in ['ADMIN', 'OWNER', 'MEMBER']) {
    testWidgets('FE-02 $role discovery with existing membership', (
      tester,
    ) async {
      final current = session(platformRole: role == 'ADMIN' ? role : null);
      fixtureContext = AuthContext(
        accessToken: current.accessToken,
        user: current.user,
        tenants: const [
          AuthTenant(
            id: 'a',
            name: 'Membership A',
            slug: 'a',
            status: 'ACTIVO',
          ),
        ],
      );
      int calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(SprintAuth.new),
            tenantDiscoveryProvider.overrideWith((ref) async {
              calls++;
              return const [
                AuthTenant(
                  id: 'b',
                  name: 'Global B',
                  slug: 'b',
                  status: 'ACTIVO',
                ),
              ];
            }),
          ],
          child: const MaterialApp(home: SelectTenantPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, role == 'ADMIN' ? 1 : 0);
      expect(
        find.text('Global B'),
        role == 'ADMIN' ? findsOneWidget : findsNothing,
      );
    });
  }
  testWidgets('FE-02 ADMIN discovery retry with memberships', (tester) async {
    final c = session(platformRole: 'ADMIN');
    fixtureContext = AuthContext(
      accessToken: c.accessToken,
      user: c.user,
      tenants: const [
        AuthTenant(id: 'a', name: 'Membership A', slug: 'a', status: 'ACTIVO'),
      ],
    );
    int calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(SprintAuth.new),
          tenantDiscoveryProvider.overrideWith((ref) async {
            if (++calls == 1) throw StateError('synthetic discovery failure');
            return const [
              AuthTenant(
                id: 'b',
                name: 'Global B',
                slug: 'b',
                status: 'ACTIVO',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: SelectTenantPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Global B'), findsOneWidget);
  });
  for (final jwtRole in ['OWNER', 'MEMBER']) {
    test(
      'FE-03 JWT $jwtRole remains presentation authority after DB role change',
      () async {
        fixtureContext = contextWithToken(token({'tenantRole': jwtRole}));
        final adapter = ContractAdapter()
          ..response = envelope({
            ...userJson,
            'role': {
              'id': 'role-a',
              'name': jwtRole == 'OWNER' ? 'MEMBER' : 'OWNER',
              'tenantId': 'a',
            },
          });
        final c = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(SprintAuth.new),
            platformApiProvider.overrideWithValue(testApi(adapter)),
          ],
        );
        addTearDown(c.dispose);
        final p = await c.read(currentTenantPermissionsProvider.future);
        expect(p.role?.name, jwtRole);
        expect(
          adapter.request,
          isNull,
          reason: 'Do not re-read DB role to interpret issued JWT',
        );
      },
    );
  }
  for (final claims in <Map<String, Object?>>[
    {'sub': 'another-user'},
    {'tenantId': 'b'},
    {'tenantRole': 'ADMIN'},
    {'exp': 1},
    {'exp': 'invalid'},
    {'tenantRole': null},
  ]) {
    test('FE-03 rejects invalid presentation claims $claims', () async {
      fixtureContext = contextWithToken(token(claims));
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(SprintAuth.new),
          platformApiProvider.overrideWithValue(
            testApi(ContractAdapter()..response = envelope(userJson)),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(
        (await c.read(currentTenantPermissionsProvider.future)).canRead,
        isFalse,
      );
    });
  }
  test('FE-03 malformed token fails closed', () async {
    fixtureContext = contextWithToken('not-a-jwt');
    final c = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(SprintAuth.new),
        platformApiProvider.overrideWithValue(
          testApi(ContractAdapter()..response = envelope(userJson)),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(
      (await c.read(currentTenantPermissionsProvider.future)).canRead,
      isFalse,
    );
  });
}
