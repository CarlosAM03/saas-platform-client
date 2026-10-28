import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/users/state/users_providers.dart';
import 'package:saas_platform_client/routes/app_router.dart';
import 'features/feature_fixtures.dart';
import 'features/users_fixtures.dart';
import 'features/tenants_fixtures.dart';

class RestoringAuth extends AuthController {
  @override
  AuthState build() => const AuthState.unknown();
  void finish() =>
      state = AuthState(status: AuthStatus.authenticated, context: session());
}

void main() {
  testWidgets(
    'FE-09 session restoration preserves the protected deep link and its query',
    (tester) async {
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(RestoringAuth.new),
          usersRepositoryProvider.overrideWithValue(FakeUsers()),
          tenantsRepositoryProvider.overrideWithValue(FakeTenants()),
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
      const route = '/users/$entityId?review=core';
      router.go(route);
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/splash');
      expect(find.text('Owner'), findsNothing);
      (c.read(authControllerProvider.notifier) as RestoringAuth).finish();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), route);
      expect(find.text('Owner'), findsOneWidget);
    },
  );
}
