import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../test/platform_api/fixtures.dart' show TestTokenStorage;

class LocalHttp extends HttpOverrides {}

String sqlValue(String value) => "'${value.replaceAll("'", "''")}'";

Future<void> localSql(String sql) async {
  final backend = const String.fromEnvironment('P2C_BACKEND_DIR').isNotEmpty
      ? const String.fromEnvironment('P2C_BACKEND_DIR')
      : '${Directory.current.resolveSymbolicLinksSync()}/../../Backend_Nestjs/saas-platform-backend';
  final result = await Process.run(
      'docker',
      [
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
        sql
      ],
      workingDirectory: backend);
  if (result.exitCode != 0) {
    throw StateError('Local P2C fixture SQL failed: ${result.stderr}');
  }
}

void main() {
  test('P2C: typed client -> NestJS -> Prisma -> PostgreSQL', () async {
    const base = String.fromEnvironment('P2C_BASE_URL',
        defaultValue: 'http://localhost:3000');
    const password = String.fromEnvironment('P2C_PASSWORD');
    final uri = Uri.parse(base);
    if (!['localhost', '127.0.0.1', '::1'].contains(uri.host) ||
        uri.scheme != 'http') {
      throw StateError('P2C accepts only a local HTTP backend');
    }
    if (password.isEmpty) {
      throw StateError(
          'Pass --dart-define=P2C_PASSWORD for the local demo seed');
    }
    await HttpOverrides.runZoned(() async {
      final storage = TestTokenStorage(token: null);
      final api = PlatformApi(ApiClient(
          config: const AppConfig(apiBaseUrl: base), storage: storage));
      expect((await api.health.ready()).database, DatabaseStatus.up);
      final session = await api.auth.login(const LoginRequest(
          email: 'owner.demo-norte@demo.example', password: password));
      await storage.writeToken(session.accessToken);
      expect((await api.auth.me()).currentTenantId, session.currentTenantId);
      await api.campaigns.list();
      final campaign = await api.campaigns.create(CreateCampaignRequest(
          name: 'P2C ${DateTime.now().microsecondsSinceEpoch}',
          description: 'Local integration test'));
      expect(campaign.createdBy, session.user.id);
      final fetched = await api.campaigns.get(campaign.id);
      expect(fetched.name, campaign.name);
      final updated = await api.campaigns.update(
          campaign.id,
          const UpdateCampaignRequest(
              name: 'P2C updated', description: FieldUpdate.set(null)));
      expect(updated.name, 'P2C updated');
      expect(updated.description, isNull);
      final page = await api.campaigns
          .list(query: const PaginationQuery(search: 'P2C updated'));
      expect(page.items.any((item) => item.id == campaign.id), isTrue);
      await api.campaigns.archive(campaign.id);
      expect((await api.campaigns.get(campaign.id)).status,
          CampaignStatus.ARCHIVADA);
      final prospects = await api.prospects.list();
      final users = await api.users.list();
      final jobs = await api.prospectingJobs.list();
      expect(prospects.items, isNotEmpty);
      expect(users.items, isNotEmpty);
      expect(jobs.items, isNotEmpty);
      await api.prospects.get(prospects.items.first.id);
      await api.users.get(users.items.first.id);
      await api.campaigns.prospects(prospects.items.first.campaignId);
      final seedJob = jobs.items.first;
      if (seedJob.id.startsWith('demo-job-')) {
        await expectLater(
            api.prospectingJobs.get(seedJob.id), throwsFormatException);
      }
      // Fixture belongs only to this local P2C run; existing jobs are untouched.
      final jobId =
          'c${DateTime.now().microsecondsSinceEpoch.toString().padLeft(24, '0')}';
      await localSql('INSERT INTO prospecting_jobs '
          '(id, tenant_id, campaign_id, requested_by, status, query, created_at, updated_at) VALUES '
          '(${sqlValue(jobId)}, ${sqlValue(session.currentTenantId!)}, ${sqlValue(campaign.id)}, '
          '${sqlValue(session.user.id)}, \'QUEUED\', '
          '\'{"keyword":"coffee","location":"Tijuana","source":"google_maps","limit":10}\'::jsonb, now(), now())');
      try {
        final job = await api.prospectingJobs.get(jobId);
        expect(job.resultsAvailable, isFalse);
        expect(job.query.source, ProspectSource.google_maps);
      } finally {
        await localSql(
            'DELETE FROM prospecting_jobs WHERE id=${sqlValue(jobId)}');
      }
      await expectLater(
          api.prospectingJobs.persist(seedJob.id),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'status', 503)
              .having((e) => (e.details as Map)['reason'], 'reason',
                  'PROSPECTOR_INTEGRATION_PENDING')));
      await api.auth.logout();
      await storage.clearToken();
    }, createHttpClient: (context) => LocalHttp().createHttpClient(context));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
