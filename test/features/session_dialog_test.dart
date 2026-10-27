import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/shared/widgets/campaign_picker.dart';
import 'package:saas_platform_client/shared/widgets/feature_widgets.dart';
import 'campaigns_fixtures.dart';
import 'feature_fixtures.dart';

void main() {
  for (final logout in [false, true]) {
    testWidgets(
      'confirmation clears on ${logout ? "logout" : "tenant switch"}',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
          ],
        );
        addTearDown(container.dispose);
        bool? approved;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      approved = await confirmAction(
                        context,
                        'Confidential tenant A campaign',
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Confidential tenant A campaign'), findsOneWidget);
        final auth =
            container.read(authControllerProvider.notifier)
                as FeatureAuthController;
        if (logout) {
          auth.setStatus(AuthStatus.unauthenticated);
        } else {
          auth.setSession(session(tenant: 'b'));
        }
        await tester.pump();
        expect(find.text('Confidential tenant A campaign'), findsNothing);
        await tester.pumpAndSettle();
        expect(approved, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  }
  testWidgets('campaign picker discards private search on JWT context change', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => pickCampaign(context, ref),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Private tenant A search');
    (container.read(authControllerProvider.notifier) as FeatureAuthController)
        .setSession(session(tenant: 'b'));
    await tester.pump();
    expect(find.text('Private tenant A search'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
