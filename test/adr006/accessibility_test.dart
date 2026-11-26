import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/tenant_registration/presentation/registration_pages.dart';
import 'package:saas_platform_client/features/tenant_registration/state/registration_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../features/feature_fixtures.dart' show FeatureAuthController, session;
import 'fixtures.dart';

void main() {
  testWidgets(
    'mobile registration focuses first invalid field and blocks duplicate submit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeRegistration()
        ..pendingRegistration = Completer<TenantRegistrationResult>();
      final c = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
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
            home: Scaffold(body: TenantRegistrationPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        FilledButton,
        'Registrar organización',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final inputs = find.byType(TextFormField);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );
      for (final item in [
        'Lab Company',
        'lab-company',
        'Lab Owner',
        'owner@example.invalid',
      ].asMap().entries) {
        await tester.ensureVisible(inputs.at(item.key));
        await tester.enterText(inputs.at(item.key), item.value);
      }
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.registrations, 1);
      await tester.ensureVisible(button);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(tester.takeException(), isNull);
      repo.pendingRegistration!.complete(registrationResult());
      await tester.pumpAndSettle();
      expect(find.text('Activación: PENDING_FIRST_ACCESS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
