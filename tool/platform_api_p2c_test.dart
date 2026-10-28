import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../test/platform_api/fixtures.dart' show TestTokenStorage;

class LocalHttp extends HttpOverrides {}

String sqlValue(String value) => "'${value.replaceAll("'", "''")}'";

Future<void> localSql(String sql) async {
  const container = String.fromEnvironment('P2C_DB_CONTAINER');
  if (container.isNotEmpty) {
    // Explicit adapter for the isolated sprint stack; never accept arbitrary DBs.
    final owner = await Process.run('docker', [
      'inspect',
      '--format',
      '{{index .Config.Labels "com.docker.compose.project"}}',
      container,
    ]);
    if (owner.exitCode != 0 ||
        owner.stdout.toString().trim() != 'prospector-frontend-sprint') {
      throw StateError('P2C DB container is not owned by the isolated sprint');
    }
    final check = await Process.run('docker', [
      'exec',
      container,
      'psql',
      '-X',
      '-Atq',
      '-U',
      'saas_local',
      '-d',
      'avance2_core',
      '-c',
      "SELECT current_database() || ':' || (current_setting('server_version_num')::int / 10000)",
    ]);
    if (check.exitCode != 0 ||
        check.stdout.toString().trim() != 'avance2_core:16') {
      throw StateError(
        'P2C requires the verified local PostgreSQL16 avance2_core database',
      );
    }
    final result = await Process.run('docker', [
      'exec',
      container,
      'psql',
      '-X',
      '-U',
      'saas_local',
      '-d',
      'avance2_core',
      '-v',
      'ON_ERROR_STOP=1',
      '-c',
      sql,
    ]);
    if (result.exitCode != 0) throw StateError('Isolated P2C SQL failed');
    return;
  }

  final backend = const String.fromEnvironment('P2C_BACKEND_DIR').isNotEmpty
      ? const String.fromEnvironment('P2C_BACKEND_DIR')
      : '${Directory.current.resolveSymbolicLinksSync()}/../../Backend_Nestjs/saas-platform-backend';
  final result = await Process.run('docker', [
    'compose',
    'exec',
    '-T',
    'db',
    'psql',
    '-U',
    'saas_local',
    '-d',
    'saas_local',
    '-v',
    'ON_ERROR_STOP=1',
    '-c',
    sql,
  ], workingDirectory: backend);
  if (result.exitCode != 0) {
    throw StateError('Local P2C fixture SQL failed: ${result.stderr}');
  }
}

void main() {
  test('P2C: Flutter -> local NestJS -> Prisma -> PostgreSQL core parity', () async {
    const base = String.fromEnvironment(
      'P2C_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
    const password = String.fromEnvironment('P2C_PASSWORD');
    final uri = Uri.parse(base);
    if (!['localhost', '127.0.0.1', '::1'].contains(uri.host) ||
        uri.scheme != 'http') {
      throw StateError('P2C accepts only a local HTTP backend');
    }
    if (password.isEmpty) {
      throw StateError(
        'Pass --dart-define=P2C_PASSWORD for the local demo seed',
      );
    }
    await HttpOverrides.runZoned(() async {
      final storage = TestTokenStorage(token: null);
      final api = PlatformApi(
        ApiClient(
          config: const AppConfig(apiBaseUrl: base),
          storage: storage,
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      String? campaignId, userId, tenantId;
      try {
        expect((await api.health.ready()).database, DatabaseStatus.up);
        final owner = await api.auth.login(
          const LoginRequest(
            email: 'owner.demo-norte@demo.example',
            password: password,
          ),
        );
        await storage.writeToken(owner.accessToken);
        expect((await api.auth.me()).currentTenantId, owner.currentTenantId);
        final tenants = await api.tenants.list();
        expect(tenants.any((t) => t.id == owner.currentTenantId), isTrue);
        expect(
          (await api.tenants.get(owner.currentTenantId!)).id,
          owner.currentTenantId,
        );
        final campaign = await api.campaigns.create(
          CreateCampaignRequest(
            name: 'P2C $suffix',
            description: 'Local parity fixture',
          ),
        );
        campaignId = campaign.id;
        expect(campaign.createdBy, owner.user.id);
        expect((await api.campaigns.get(campaign.id)).name, campaign.name);
        final updated = await api.campaigns.update(
          campaign.id,
          const UpdateCampaignRequest(
            name: 'P2C updated',
            description: FieldUpdate.set(null),
            status: CampaignStatus.PAUSADA,
          ),
        );
        expect(updated.description, isNull);
        expect(updated.status, CampaignStatus.PAUSADA);
        expect(
          (await api.campaigns.list(
            query: const PaginationQuery(search: 'P2C updated'),
          )).items.any((c) => c.id == campaign.id),
          isTrue,
        );
        final manual = await api.prospects.create(
          CreateProspectRequest(
            campaignId: campaign.id,
            name: 'Manual $suffix',
            phone: const FieldUpdate.set('123'),
          ),
        );
        expect(manual.source, PersistedProspectSource.manual);
        expect(
          (await api.prospects.get(manual.id)).source,
          PersistedProspectSource.manual,
        );
        final manualEdit = await api.prospects.update(
          manual.id,
          const UpdateProspectRequest(phone: FieldUpdate.set(null)),
        );
        expect(manualEdit.phone, isNull);
        expect(manualEdit.name, manual.name);
        final upload = ApiUploadFile(
          filename: 'p2c.csv',
          bytes: utf8.encode(
            'name,email\nCSV $suffix,p2c-$suffix@example.com\n',
          ),
        );
        final preview = await api.prospects.previewImport(
          campaignId: campaign.id,
          upload: upload,
        );
        expect(preview.summary.newCount, 1);
        expect(
          preview.rows.single.classification,
          ProspectImportClassification.NEW,
        );
        final result = await api.prospects.confirmImport(
          campaignId: campaign.id,
          upload: upload,
          previewReference: preview.previewReference,
          decisions: [
            ProspectImportDecision(
              record: preview.rows.single.record,
              action: ProspectImportAction.CREATE,
            ),
          ],
        );
        expect(result.summary.created, 1);
        final csv = await api.prospects.get(result.rows.single.prospectId!);
        expect(csv.source, PersistedProspectSource.csv);
        expect(
          (await api.campaigns.prospects(campaign.id)).items.map((p) => p.id),
          containsAll([manual.id, csv.id]),
        );
        expect(
          (await api.prospects.list(
            query: PaginationQuery(search: 'CSV $suffix'),
          )).items.single.id,
          csv.id,
        );
        final user = await api.users.create(
          CreateUserRequest(
            name: 'P2C user',
            email: 'p2c-$suffix@example.com',
            // The reserved seed accepts a long random secret; user creation also requires a special character.
            password: '${password}Aa1!',
          ),
        );
        userId = user.id;
        expect(user.role?.name, RoleName.MEMBER);
        expect((await api.users.get(user.id)).id, user.id);
        expect(
          (await api.users.update(
            user.id,
            const UpdateUserRequest(name: 'P2C user updated'),
          )).name,
          'P2C user updated',
        );
        expect(
          (await api.users.list(
            query: PaginationQuery(search: 'p2c-$suffix@example.com'),
          )).items.single.id,
          user.id,
        );
        final jobs = await api.prospectingJobs.list();
        expect(jobs.items, isNotEmpty);
        // Existing seed Jobs carry source=demo. Keep that drift visible and use a temporary contractual fixture for detail.
        final seedJob = jobs.items.first;
        if (seedJob.id.startsWith('demo-job-')) {
          await expectLater(
            api.prospectingJobs.get(seedJob.id),
            throwsFormatException,
          );
        }
        final jobId = 'c${suffix.toString().padLeft(24, '0')}';
        await localSql(
          'INSERT INTO prospecting_jobs (id,tenant_id,campaign_id,requested_by,status,query,created_at,updated_at) VALUES '
          '(${sqlValue(jobId)},${sqlValue(owner.currentTenantId!)},${sqlValue(campaign.id)},${sqlValue(owner.user.id)},'
          "'QUEUED','{\"keyword\":\"coffee\",\"location\":\"Tijuana\",\"source\":\"google_maps\",\"limit\":10}'::jsonb,now(),now())",
        );
        final job = await api.prospectingJobs.get(jobId);
        expect(job.query.source, ProspectingSource.google_maps);
        expect(job.resultsAvailable, isFalse);
        await api.campaigns.archive(campaign.id);
        expect(
          (await api.campaigns.get(campaign.id)).status,
          CampaignStatus.ARCHIVADA,
        );
        final admin = await api.auth.login(
          const LoginRequest(email: 'admin@demo.example', password: password),
        );
        await storage.writeToken(admin.accessToken);
        final selected = await api.auth.selectTenant(
          SelectTenantRequest(tenantId: owner.currentTenantId!),
        );
        await storage.writeToken(selected.accessToken);
        await api.users.deactivate(user.id);
        expect((await api.users.get(user.id)).status, UserStatus.INACTIVO);
        final tenant = await api.tenants.create(
          CreateTenantRequest(name: 'P2C tenant $suffix', slug: 'p2c-$suffix'),
        );
        tenantId = tenant.id;
        expect((await api.tenants.get(tenant.id)).slug, tenant.slug);
        final switched = await api.auth.selectTenant(
          SelectTenantRequest(tenantId: tenant.id),
        );
        await storage.writeToken(switched.accessToken);
        expect((await api.auth.me()).currentTenantId, tenant.id);
        expect((await api.campaigns.list()).items, isEmpty);
        await api.auth.logout();
        await storage.clearToken();
      } finally {
        // Remove only IDs allocated by this run; preserve seed data and unrelated local records.
        if (campaignId != null) {
          final id = sqlValue(campaignId);
          await localSql(
            'BEGIN; DELETE FROM campaign_prospects WHERE campaign_id=$id; DELETE FROM prospects WHERE campaign_id=$id; DELETE FROM prospecting_jobs WHERE campaign_id=$id; DELETE FROM campaigns WHERE id=$id; COMMIT;',
          );
        }
        if (userId != null) {
          final id = sqlValue(userId);
          await localSql(
            'BEGIN; DELETE FROM user_tenants WHERE user_id=$id; DELETE FROM users WHERE id=$id; COMMIT;',
          );
        }
        if (tenantId != null) {
          final id = sqlValue(tenantId);
          await localSql(
            'BEGIN; DELETE FROM roles WHERE tenant_id=$id; DELETE FROM tenants WHERE id=$id; COMMIT;',
          );
        }
        await storage.clearToken();
      }
    }, createHttpClient: (context) => LocalHttp().createHttpClient(context));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
