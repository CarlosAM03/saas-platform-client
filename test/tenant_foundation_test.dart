import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/presentation/auth_pages.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/shared/models/api_models.dart';

AuthContext adminContext({String? tenantId}) => AuthContext(
      accessToken: tenantId == null ? 'admin-token' : 'tenant-token',
      user: AuthUser(
        id: 'admin',
        name: 'Demo Admin',
        email: 'admin@demo.example',
        platformRole: 'ADMIN',
        status: 'ACTIVO',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      tenants: const [],
      currentTenantId: tenantId,
    );

class AdminControllerFixture extends AuthController {
  String? selectedTenant;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, context: adminContext());

  @override
  Future<void> selectTenant(String tenantId) async {
    selectedTenant = tenantId;
    state = AuthState(
        status: AuthStatus.authenticated,
        context: adminContext(tenantId: tenantId));
  }
}

void main() {
  testWidgets(
      'ADMIN without memberships sees discovered tenants and can select one',
      (tester) async {
    final container = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(AdminControllerFixture.new),
      tenantDiscoveryProvider.overrideWith((ref) async => const [
            AuthTenant(
                id: 'demo-tenant-norte',
                name: 'Demo Norte',
                slug: 'demo-norte',
                status: 'ACTIVO'),
            AuthTenant(
                id: 'demo-tenant-sur',
                name: 'Demo Sur',
                slug: 'demo-sur',
                status: 'ACTIVO'),
          ]),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SelectTenantPage())));
    await tester.pumpAndSettle();
    expect(find.text('Demo Norte'), findsOneWidget);
    expect(find.text('Demo Sur'), findsOneWidget);
    await tester.tap(find.text('Demo Sur'));
    await tester.pumpAndSettle();
    expect(
        (container.read(authControllerProvider.notifier)
                as AdminControllerFixture)
            .selectedTenant,
        'demo-tenant-sur');
  });
}
