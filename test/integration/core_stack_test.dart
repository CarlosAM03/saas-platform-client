import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';
import 'package:saas_platform_client/features/auth/state/tenant_permissions.dart';
import 'package:saas_platform_client/features/dashboard/state/dashboard_providers.dart';
import 'package:saas_platform_client/features/prospecting_jobs/state/prospecting_capabilities.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../platform_api/fixtures.dart' show TestTokenStorage;

void main() {
  const manifest = String.fromEnvironment('CORE_MANIFEST');
  test(
    'Flutter → compiled production NestJS → PostgreSQL, Service absent, CSV 600',
    () async {
      final fixture =
          jsonDecode(File(manifest).readAsStringSync()) as Map<String, dynamic>;
      final origin = Uri.parse(fixture['apiBaseUrl'] as String);
      if (!['localhost', '127.0.0.1'].contains(origin.host) ||
          fixture['productionEntrypoint'] != true ||
          fixture['serviceCredentials'] != false) {
        throw StateError(
          'Requires the explicit isolated production-entrypoint core stack',
        );
      }
      final storage = TestTokenStorage(token: null);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(apiBaseUrl: origin.origin),
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
      await auth.selectTenant(fixture['tenantId'] as String);
      expect(
        (await container.read(currentTenantPermissionsProvider.future)).canRead,
        isTrue,
      );
      final api = container.read(platformApiProvider);
      final caps = await container.read(
        verifiedProspectingCapabilitiesProvider.future,
      );
      expect(
        caps.create || caps.cancel || caps.persist || caps.export,
        isFalse,
      );
      expect(caps.reason, 'PROSPECTOR_INTEGRATION_PENDING');
      final campaignId = fixture['campaignId'] as String;
      expect((await api.tenants.list()).length, 2);
      final user = await api.users.create(
        CreateUserRequest(
          name: 'Private core user',
          email: 'core-${DateTime.now().microsecondsSinceEpoch}@example.com',
          password: 'DisposableCoreOnly123!',
        ),
      );
      expect(
        (await api.users.update(
          user.id,
          const UpdateUserRequest(name: 'Private edited core user'),
        )).name,
        'Private edited core user',
      );
      final campaign = await api.campaigns.create(
        const CreateCampaignRequest(name: 'Controlled core campaign'),
      );
      expect(
        (await api.campaigns.update(
          campaign.id,
          const UpdateCampaignRequest(name: 'Controlled updated campaign'),
        )).name,
        'Controlled updated campaign',
      );
      await api.campaigns.archive(campaign.id);
      final manual = await api.prospects.create(
        CreateProspectRequest(
          campaignId: campaignId,
          name: 'Manual isolated core fixture',
        ),
      );
      expect(
        (await api.prospects.update(
          manual.id,
          const UpdateProspectRequest(name: 'Edited isolated core fixture'),
        )).name,
        'Edited isolated core fixture',
      );
      final initial = await container.read(dashboardProvider.future);
      expect(initial.prospects.meta.total, 1);
      final upload = ApiUploadFile(
        filename: 'synthetic-600.csv',
        bytes: File(fixture['csvPath'] as String).readAsBytesSync(),
      );
      final preview = await api.prospects.previewImport(
        campaignId: campaignId,
        upload: upload,
      );
      expect(preview.summary.total, 600);
      expect(preview.summary.newCount, 600);
      final decisions = preview.rows
          .map(
            (row) => ProspectImportDecision(
              record: row.record,
              action: ProspectImportAction.CREATE,
            ),
          )
          .toList();
      final result = await api.prospects.confirmImport(
        campaignId: campaignId,
        upload: upload,
        previewReference: preview.previewReference,
        decisions: decisions,
      );
      expect(result.summary.created, 600);
      await expectLater(
        api.prospects.confirmImport(
          campaignId: campaignId,
          upload: upload,
          previewReference: preview.previewReference,
          decisions: decisions,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'replay',
            ApiErrorKind.conflict,
          ),
        ),
      );
      container.invalidate(dashboardProvider);
      final dashboard = await container.read(dashboardProvider.future);
      expect(dashboard.prospects.meta.total, 601);
      expect(dashboard.jobs.meta.total, 0);
      await expectLater(
        api.prospectingJobs.create(
          CreateProspectingJobRequest(
            campaignId: campaignId,
            query: const ProspectingQuery(
              keyword: 'software',
              location: 'Tijuana',
              source: ProspectingSource.google_maps,
              limit: 1,
            ),
          ),
          idempotencyKey: 'core-disabled-intention',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'disabled',
            ApiErrorKind.serviceUnavailable,
          ),
        ),
      );
      expect((await api.prospectingJobs.list()).meta.total, 0);
      await auth.selectTenant(fixture['otherTenantId'] as String);
      final other = await container.read(dashboardProvider.future);
      expect(other.prospects.meta.total, 0);
      expect(other.campaigns.meta.total, 0);
      await expectLater(
        api.prospects.get(manual.id),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'cross tenant',
            ApiErrorKind.notFound,
          ),
        ),
      );
      await expectLater(
        api.prospects.previewImport(campaignId: campaignId, upload: upload),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'cross tenant CSV',
            ApiErrorKind.notFound,
          ),
        ),
      );
      await auth.logout();
      expect(container.read(sessionScopeProvider), isNull);
      expect(storage.token, isNull);
      final egress =
          jsonDecode(File(fixture['egressFile'] as String).readAsStringSync())
              as Map<String, dynamic>;
      expect(egress['calls'], 0);
      final evidence = File('build/test-evidence/core-stack.json');
      evidence.parent.createSync(recursive: true);
      evidence.writeAsStringSync(
        jsonEncode({
          'productionEntrypoint': true,
          'serviceCredentials': false,
          'httpDependencyCalls': 0,
          'csvRows': 600,
          'created': 600,
          'dashboardProspects': 601,
          'csvReplay': 409,
          'crossTenant': 404,
          'generation': 503,
          'fictionalJobs': 0,
          'logout': true,
        }),
      );
    },
    skip: manifest.isEmpty
        ? 'Requires explicit CORE_MANIFEST; no mock substitute'
        : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
