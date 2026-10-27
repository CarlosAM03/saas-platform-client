import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/prospecting_capabilities.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/prospecting_jobs_providers.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../platform_api/fixtures.dart' show TestTokenStorage;

void main() {
  const manifest = String.fromEnvironment('MVP_MANIFEST');
  test(
    'real Flutter Auth/PlatformApi/Riverpod → Nest → FastAPI → controlled EnginePort → callbacks → PostgreSQL → Flutter',
    () async {
      final fixture =
          jsonDecode(File(manifest).readAsStringSync()) as Map<String, dynamic>;
      final uri = Uri.parse(fixture['apiBaseUrl'] as String);
      if (!['127.0.0.1', 'localhost'].contains(uri.host)) {
        throw StateError('Only the disposable loopback stack is allowed');
      }
      final storage = TestTokenStorage(token: null);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(apiBaseUrl: uri.origin),
          ),
          secureTokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.read(authControllerProvider.notifier);
      await auth.login(
        fixture['email'] as String,
        fixture['password'] as String,
      );
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(
        container.read(authControllerProvider).context!.currentTenantId,
        isNull,
      );
      final tenant = fixture['tenantId'] as String;
      await auth.selectTenant(tenant);
      expect(
        (await container.read(currentTenantPermissionsProvider.future)).canRead,
        isTrue,
      );
      final capSub = container.listen(
        verifiedProspectingCapabilitiesProvider,
        (_, __) {},
      );
      addTearDown(capSub.close);
      final caps = await container.read(
        verifiedProspectingCapabilitiesProvider.future,
      );
      expect(caps.create, isTrue);
      expect(caps.cancel || caps.persist || caps.export, isFalse);
      final api = container.read(platformApiProvider);
      final repo = container.read(prospectingJobsRepositoryProvider);
      CreateProspectingJobRequest request(String keyword) =>
          CreateProspectingJobRequest(
            campaignId: fixture['campaignId'] as String,
            query: ProspectingQuery(
              keyword: keyword,
              location: 'Tijuana',
              source: ProspectingSource.google_maps,
              limit: 2,
            ),
          );
      Future<ProspectingJobDetail> terminal(String id) async {
        final done = Completer<ProspectingJobDetail>();
        final sub = container.listen(jobMonitorProvider(id), (_, next) {
          next.whenData((job) {
            if (!isJobActive(job.status) && !done.isCompleted) {
              done.complete(job);
            }
          });
          if (next.hasError && !done.isCompleted) {
            done.completeError(next.error!);
          }
        }, fireImmediately: true);
        try {
          return await done.future.timeout(const Duration(seconds: 15));
        } finally {
          sub.close();
        }
      }

      final key = 'flutter-intention-${DateTime.now().microsecondsSinceEpoch}';
      final started = await repo.create(request('slow'), key);
      final completed = await terminal(started.id);
      expect(completed.status, ProspectingJobStatus.COMPLETED);
      expect(completed.resultsAvailable, isTrue);
      expect(completed.progress, isNull);
      expect(completed.results!.single.name, 'Controlled Cafe');
      expect(completed.results!.single.sourceIdentifier, isNull);
      expect(completed.results!.single.metadata, isNull);
      expect(completed.resultsExpiresAt!.isAfter(DateTime.now()), isTrue);
      expect((await repo.create(request('slow'), key)).id, started.id);
      await expectLater(
        repo.create(request('empty'), key),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.conflict,
          ),
        ),
      );
      final failure = await terminal(
        (await repo.create(request('fail'), '$key-fail')).id,
      );
      expect(failure.status, ProspectingJobStatus.FAILED);
      expect(failure.retryAllowed, isTrue);
      expect(failure.failureCode, 'ENGINE_EXTRACTION_FAILED');
      expect(failure.results, isNull);
      final empty = await terminal(
        (await repo.create(request('empty'), '$key-empty')).id,
      );
      expect(empty.resultsAvailable, isTrue);
      expect(empty.results, isEmpty);
      expect(
        (await api.prospectingJobs.list()).items.map((j) => j.id),
        containsAll([completed.id, failure.id, empty.id]),
      );
      expect(
        (await api.prospects.list()).items,
        isEmpty,
      ); // snapshots did not create campaign prospects.
      final manual = await api.prospects.create(
        CreateProspectRequest(
          campaignId: fixture['campaignId'] as String,
          name: 'Manual isolated fixture',
        ),
      );
      expect(manual.name, 'Manual isolated fixture');
      final upload = ApiUploadFile(
        filename: 'mvp.csv',
        bytes: utf8.encode('name,phone\nCSV isolated fixture,00123\n'),
      );
      final preview = await api.prospects.previewImport(
        campaignId: fixture['campaignId'] as String,
        upload: upload,
      );
      final imported = await api.prospects.confirmImport(
        campaignId: fixture['campaignId'] as String,
        upload: upload,
        previewReference: preview.previewReference,
        decisions: [
          ProspectImportDecision(
            record: preview.rows.single.record,
            action: ProspectImportAction.CREATE,
          ),
        ],
      );
      expect(imported.summary.created, 1);
      expect((await api.prospects.list()).meta.total, 2);
      final dashboard = await container.read(dashboardProvider.future);
      expect(dashboard, isNotNull);
      await auth.selectTenant(fixture['otherTenantId'] as String);
      expect((await api.prospectingJobs.list()).items, isEmpty);
      await expectLater(
        api.prospectingJobs.get(completed.id),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.notFound,
          ),
        ),
      );
      await auth.selectTenant(tenant);
      final running = await repo.create(request('slow'), '$key-logout');
      final sub = container.listen(jobMonitorProvider(running.id), (_, __) {});
      await auth.logout();
      expect(container.read(sessionScopeProvider), isNull);
      expect(storage.token, isNull);
      sub.close();
      final output = Directory('build/test-evidence');
      output.createSync(recursive: true);
      File('${output.path}/prospector-stack.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'engine': 'controlled EnginePort; no public scraping',
          'backendImplementation': 'b6cd40f5c00990411bd6f46a22991c9be60de4bf',
          'tenantId': tenant,
          'completedJobId': completed.id,
          'failedJobId': failure.id,
          'emptyJobId': empty.id,
          'results': completed.results!.length,
          'manualProspects': 1,
          'csvCreated': imported.summary.created,
          'tenantIsolation': true,
          'logoutDuringJob': true,
        }),
      );
    },
    skip: manifest.isEmpty
        ? 'Requires explicit MVP_MANIFEST from the disposable real HTTP stack; no mock substitute'
        : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
