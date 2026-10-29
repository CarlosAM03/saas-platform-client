import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/activation/activation_bootstrap.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/tenant_registration/presentation/registration_pages.dart';
import 'package:saas_platform_client/features/tenant_registration/state/activation_controller.dart';
import 'package:saas_platform_client/features/tenant_registration/state/registration_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/routes/app_router.dart';
import '../features/feature_fixtures.dart' show FeatureAuthController, session;
import '../features/tenants_fixtures.dart';
import '../sprint_deeplink_regression_test.dart' show RestoringAuth;
import 'fixtures.dart';

void main() {
  for (final tenant in <String?>[null, 'a']) {
    testWidgets(
      'ADMIN tenant=$tenant registers four fields and sees independent delivery failure',
      (tester) async {
        final repo = FakeRegistration()..delivery = 'FAILED';
        final c = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            tenantRegistrationRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(c.dispose);
        (c.read(authControllerProvider.notifier) as FeatureAuthController)
            .setSession(session(tenant: tenant, platformRole: 'ADMIN'));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(
              home: Scaffold(body: TenantRegistrationPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNWidgets(4));
        for (final entry in [
          'Company',
          'new-company',
          'Owner',
          'owner@example.invalid',
        ].asMap().entries) {
          await tester.enterText(
            find.byType(TextFormField).at(entry.key),
            entry.value,
          );
        }
        await tester.tap(
          find.widgetWithText(FilledButton, 'Registrar organización'),
        );
        await tester.pumpAndSettle();
        expect(repo.registrations, 1);
        expect(repo.request!.toJson().keys.toSet(), {
          'tenantName',
          'tenantSlug',
          'ownerName',
          'ownerEmail',
        });
        expect(find.text('Activación: PENDING_FIRST_ACCESS'), findsOneWidget);
        expect(find.text('Entrega: FAILED'), findsOneWidget);
        expect(find.textContaining('no entrega al buzón'), findsOneWidget);
        for (final label in [
          'Vencimiento del enlace:',
          'Último intento:',
          'Aceptación del transporte:',
          'Activación completada:',
        ]) {
          expect(find.textContaining(label), findsOneWidget);
        }
        expect(c.read(authControllerProvider).context!.currentTenantId, tenant);
      },
    );
  }
  for (final role in RoleName.values) {
    testWidgets(
      '$role cannot register or query/resend onboarding by direct page',
      (tester) async {
        final repo = FakeRegistration();
        final c = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            tenantRegistrationRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(c.dispose);
        (c.read(authControllerProvider.notifier) as FeatureAuthController)
            .setSession(session(role: role));
        for (final page in [
          const TenantRegistrationPage(),
          const TenantOnboardingPage('test-tenant'),
        ]) {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: MaterialApp(home: Scaffold(body: page)),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('No tienes permisos para realizar esta acción.'),
            findsOneWidget,
          );
          expect(find.byType(TextFormField), findsNothing);
        }
        expect(repo.registrations, 0);
        expect(repo.queries, 0);
        expect(repo.resends, 0);
      },
    );
  }
  testWidgets(
    'ADMIN onboarding query and confirmed resend, with no automatic retry',
    (tester) async {
      final repo = FakeRegistration();
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          tenantsRepositoryProvider.overrideWithValue(FakeTenants()),
          tenantRegistrationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      (c.read(authControllerProvider.notifier) as FeatureAuthController)
          .setSession(session(tenant: null, platformRole: 'ADMIN'));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(body: TenantOnboardingPage('tenant')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.queries, 1);
      await tester.tap(find.text('Reenviar enlace de activación'));
      await tester.pumpAndSettle();
      expect(repo.resends, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(repo.resends, 1);
    },
  );
  testWidgets('COMPLETED onboarding never offers resend', (tester) async {
    final c = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        currentTenantPermissionsProvider.overrideWith(
          (ref) async => const TenantPermissions(admin: true),
        ),
        onboardingControllerProvider(
          'tenant',
        ).overrideWith((ref) => CompletedOnboarding(ref, 'tenant')),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: Scaffold(body: TenantOnboardingPage('tenant')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reenviar enlace de activación'), findsNothing);
  });
  testWidgets(
    'activation route stays public during unknown auth and restoration transitions',
    (tester) async {
      final repo = FakeRegistration();
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(RestoringAuth.new),
          tenantRegistrationRepositoryProvider.overrideWithValue(repo),
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
      router.go('/activate');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/activate');
      (c.read(authControllerProvider.notifier) as RestoringAuth).finish();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/activate');
      for (final status in AuthStatus.values) {
        expect(redirectForAuth(AuthState(status: status), '/activate'), isNull);
      }
      expect(repo.redeems, 0);
    },
  );
  for (final signedIn in [false, true]) {
    testWidgets(
      'startup activation and LOGIN_REQUIRED go to login, existing session=$signedIn',
      (tester) async {
        // Simulate the engine having cached the original location before main.
        // The router must override it, not retain its query for restoration.
        tester.binding.platformDispatcher.defaultRouteNameTestValue =
            '/activate?code=${activationCode()}';
        addTearDown(
          tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
        );
        final repo = FakeRegistration();
        final boot = captureActivationLocation(
          () => 'http://localhost/#/activate?code=${activationCode()}',
          (_) {},
        );
        final c = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            tenantRegistrationRepositoryProvider.overrideWithValue(repo),
            activationBootstrapProvider.overrideWithValue(boot),
            tenantsRepositoryProvider.overrideWithValue(FakeTenants()),
          ],
        );
        addTearDown(c.dispose);
        final auth =
            c.read(authControllerProvider.notifier) as FeatureAuthController;
        if (!signedIn) auth.setStatus(AuthStatus.unauthenticated);
        final originalContext = c.read(authControllerProvider).context;
        final router = c.read(appRouterProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/activate');
        expect(router.routeInformationProvider.value.uri.hasQuery, isFalse);
        expect(boot.takeCode(), isNull);
        expect(repo.redeems, 1);
        await tester.enterText(find.byType(TextFormField), passwordValue());
        await tester.tap(find.text('Establecer contraseña'));
        await tester.pumpAndSettle();
        expect(repo.completions, 1);
        expect(router.routeInformationProvider.value.uri.path, '/login');
        expect(
          identical(c.read(authControllerProvider).context, originalContext),
          isTrue,
        );
        expect(find.text('Iniciar sesión'), findsOneWidget);
        // A subsequent normal login transition must not remain pinned to login.
        auth.setStatus(AuthStatus.loading);
        await tester.pump();
        auth.setSession(session(tenant: null, platformRole: 'ADMIN'));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/select-tenant',
        );
      },
    );
  }
  test('late registration cannot populate a changed session', () async {
    final repo = FakeRegistration()
      ..pendingRegistration = Completer<TenantRegistrationResult>();
    final c = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        tenantsRepositoryProvider.overrideWithValue(FakeTenants()),
        tenantRegistrationRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    final auth =
        c.read(authControllerProvider.notifier) as FeatureAuthController;
    auth.setSession(session(platformRole: 'ADMIN'));
    final sub = c.listen(registrationControllerProvider, (_, __) {});
    addTearDown(sub.close);
    final controller = c.read(registrationControllerProvider.notifier);
    final pending = controller.register(
      const RegisterTenantRequest(
        tenantName: 'Company',
        tenantSlug: 'company',
        ownerName: 'Owner',
        ownerEmail: 'owner@example.invalid',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    auth.setSession(session(tenant: 'b', platformRole: 'ADMIN'));
    await Future<void>.delayed(Duration.zero);
    repo.pendingRegistration!.complete(registrationResult());
    await pending;
    expect(c.read(registrationControllerProvider).result, isNull);
    await Future<void>.delayed(Duration.zero);
  });
}

class CompletedOnboarding extends OnboardingController {
  CompletedOnboarding(super.ref, super.id);
  @override
  Future<void> refresh() async {
    state = OnboardingState(data: onboarding(activation: 'COMPLETED'));
  }
}
