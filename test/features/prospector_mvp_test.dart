import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/campaigns/state/campaigns_providers.dart';
import 'package:saas_platform_client/features/prospecting_jobs/presentation/generate_page.dart';
import 'package:saas_platform_client/features/prospecting_jobs/presentation/jobs_pages.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/prospecting_capabilities.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/prospecting_jobs_providers.dart';
import 'package:saas_platform_client/routes/app_router.dart'
    show ScopedFeaturePage;
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'feature_fixtures.dart';
import 'campaigns_fixtures.dart';
import 'pending_features_test.dart' show FakeJobs;

const capabilities = {
  'contractVersion': 'prospector-mvp-v1',
  'create': true,
  'cancel': false,
  'persist': false,
  'export': false,
  'reason': null,
  'source': 'google_maps',
  'minLimit': 1,
  'maxLimit': 100,
  'resultsTtlSeconds': 3600,
};

class DelayedCapabilities extends ContractAdapter {
  final pending = <Completer<ResponseBody>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final done = Completer<ResponseBody>();
    pending.add(done);
    return done.future;
  }

  void finish(int i, bool create) => pending[i].complete(
    ResponseBody.fromString(
      jsonEncode(
        envelope({
          ...capabilities,
          'create': create,
          'reason': create ? null : 'TENANT_QUOTA_EXHAUSTED',
        }),
      ),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    ),
  );
}

class SnapshotJobs extends FakeJobs {
  SnapshotJobs(this.fields);
  final Map<String, dynamic> fields;
  @override
  Future<ProspectingJobDetail> get(String id) async {
    reads++;
    return ProspectingJobDetail.fromJson({...detailJson, ...fields});
  }
}

Future<void> mountJob(WidgetTester tester, SnapshotJobs jobs) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(FeatureAuthController.new),
        prospectingJobsRepositoryProvider.overrideWithValue(jobs),
        prospectingCapabilitiesProvider.overrideWithValue(
          const ProspectingCapabilities(create: true),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: JobDetailPage(entityId))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'availability distinguishes disabled, missing policy, unreachable, verification, capacity and quota',
    () {
      const reasons = [
        'PROSPECTOR_INTEGRATION_PENDING',
        'PROSPECTOR_POLICY_NOT_CONFIGURED',
        'PROSPECTOR_SERVICE_UNAVAILABLE',
        'PROSPECTOR_VERIFICATION_FAILED',
        'PROSPECTOR_CAPACITY_EXHAUSTED',
        'TENANT_QUOTA_EXHAUSTED',
      ];
      final messages = reasons.map(prospectingUnavailableMessage).toSet();
      expect(messages.length, reasons.length);
      expect(
        prospectingUnavailableMessage(reasons.first),
        contains('importar prospectos mediante CSV'),
      );
    },
  );

  for (final status in [200, 404, 503]) {
    test(
      'capabilities verifies the actual contract and fails closed for HTTP $status',
      () async {
        final adapter = ContractAdapter()
          ..status = status
          ..response = status == 200
              ? envelope(capabilities)
              : apiError(status);
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            platformApiProvider.overrideWithValue(testApi(adapter)),
          ],
        );
        addTearDown(container.dispose);
        final sub = container.listen(
          verifiedProspectingCapabilitiesProvider,
          (_, __) {},
        );
        addTearDown(sub.close);
        final result = await container.read(
          verifiedProspectingCapabilitiesProvider.future,
        );
        expect(result.create, status == 200);
        expect(result.cancel || result.persist || result.export, isFalse);
        expect(adapter.request!.path, '/api/v1/prospecting-jobs/capabilities');
      },
    );
  }
  test(
    'future/malformed/unsupported capabilities cannot activate operations',
    () {
      for (final change in [
        {'contractVersion': 'future'},
        {'cancel': true},
        {'persist': true},
        {'export': true},
        {'maxLimit': 101},
        {'create': 'true'},
      ]) {
        expect(
          () => ProspectingPolicyStatus.fromJson({...capabilities, ...change}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'a late capability response cannot activate the next tenant or logged-out session',
    () async {
      final adapter = DelayedCapabilities();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          platformApiProvider.overrideWithValue(testApi(adapter)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        verifiedProspectingCapabilitiesProvider,
        (_, __) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final auth =
          container.read(authControllerProvider.notifier)
              as FeatureAuthController;
      auth.setSession(session(tenant: 'b'));
      final nextTenant = container.read(
        verifiedProspectingCapabilitiesProvider.future,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      adapter.finish(1, false);
      await nextTenant;
      adapter.finish(0, true);
      expect(
        (await container.read(
          verifiedProspectingCapabilitiesProvider.future,
        )).create,
        isFalse,
      );
      auth.setStatus(AuthStatus.unauthenticated);
      expect(
        (await container.read(
          verifiedProspectingCapabilitiesProvider.future,
        )).create,
        isFalse,
      );
    },
  );
  testWidgets(
    'COMPLETED empty snapshot is a valid result and future operations stay disabled',
    (tester) async {
      await mountJob(
        tester,
        SnapshotJobs({
          'status': 'COMPLETED',
          'resultsAvailable': true,
          'results': [],
          'resultsExpiresAt': DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String(),
          'progress': null,
        }),
      );
      expect(find.text('La búsqueda no encontró negocios.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Guardar en campaña'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining('Resultados disponibles hasta:'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'expired snapshot hides stale retained results and preserves Job history',
    (tester) async {
      await mountJob(
        tester,
        SnapshotJobs({
          'status': 'COMPLETED',
          'resultsAvailable': true,
          'results': [
            {'name': 'Expired business', 'source': 'google_maps'},
          ],
          'resultsExpiresAt': DateTime.now()
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
          'progress': null,
        }),
      );
      expect(find.text('Expired business'), findsNothing);
      expect(find.text('Completado'), findsOneWidget);
      expect(
        find.textContaining('no están disponibles o vencieron'),
        findsOneWidget,
      );
    },
  );
  for (final allowed in [true, false]) {
    testWidgets('manual retry requires confirmed capacity release: $allowed', (
      tester,
    ) async {
      await mountJob(
        tester,
        SnapshotJobs({
          'status': 'FAILED',
          'retryAllowed': allowed,
          'resultsAvailable': false,
          'results': null,
          'failureCode': allowed
              ? 'ENGINE_EXTRACTION_FAILED'
              : 'FINAL_EVENT_TIMEOUT',
        }),
      );
      expect(
        find.text('Repetir búsqueda manualmente'),
        allowed ? findsOneWidget : findsNothing,
      );
      if (!allowed) {
        expect(
          find.textContaining('No se confirmó que la ejecución haya terminado'),
          findsOneWidget,
        );
      }
    });
  }
  testWidgets(
    'confirmation is cancelled on tenant replacement and uncertain 503 keeps one intention',
    (tester) async {
      final jobs = FakeJobs()
        ..createError = const ApiException(
          kind: ApiErrorKind.serviceUnavailable,
          statusCode: 503,
          message: 'uncertain',
          details: {
            'reason': 'PROSPECTOR_DISPATCH_UNCERTAIN',
            'jobId': entityId,
          },
        );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FeatureAuthController.new),
          campaignsRepositoryProvider.overrideWithValue(FakeCampaigns()),
          prospectingJobsRepositoryProvider.overrideWithValue(jobs),
          prospectingCapabilitiesProvider.overrideWithValue(
            const ProspectingCapabilities(create: true),
          ),
          currentTenantPermissionsProvider.overrideWith(
            (ref) async =>
                const TenantPermissions(role: RoleName.OWNER, hasTenant: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ScopedFeaturePage(child: GeneratePage())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> fill() async {
        await tester.tap(find.text('Seleccionar campaña'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Campaign'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), 'cafes');
        await tester.enterText(find.byType(TextFormField).at(1), 'Tijuana');
      }

      await fill();
      await tester.tap(find.text('Iniciar búsqueda'));
      await tester.pumpAndSettle();
      expect(jobs.keys, isEmpty);
      (container.read(authControllerProvider.notifier) as FeatureAuthController)
          .setSession(session(tenant: 'b'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar búsqueda'), findsNothing);
      expect(jobs.keys, isEmpty);
      await fill();
      await tester.tap(find.text('Iniciar búsqueda'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(find.text('Consultar trabajo incierto'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse,
      );
      await tester.tap(find.text('Consultar misma solicitud'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(jobs.keys, hasLength(2));
      expect(jobs.keys[0], jobs.keys[1]);
      jobs.createError = const ApiException(
        kind: ApiErrorKind.rateLimited,
        statusCode: 429,
        message: 'quota',
        details: {'reason': 'TENANT_QUOTA_EXHAUSTED'},
      );
      await tester.tap(find.text('Consultar misma solicitud'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Se agotó la cuota de búsquedas'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isTrue,
      );
    },
  );
}
