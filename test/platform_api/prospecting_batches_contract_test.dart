import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';

import 'fixtures.dart';

void main() {
  final receipt = {
    'snapshotId': 'fixture-snapshot',
    'processedCount': 1,
    'omittedCount': 1,
    'committedAt': stamp,
    'ackAt': null,
    'purgedAt': null,
  };
  final batch = {
    'id': 'batch',
    'campaignId': 'campaign',
    'admission': 'UNCERTAIN',
    'createdAt': stamp,
    'jobs': [
      {
        'id': 'job',
        'position': 0,
        'state': null,
        'availability': null,
        'progress': null,
        'confirmation': receipt,
      },
    ],
  };
  late ContractAdapter adapter;
  late ProspectingBatchesApi api;
  setUp(() {
    adapter = ContractAdapter();
    api = PlatformApi(
      ApiClient(
        config: const AppConfig(apiBaseUrl: 'http://localhost'),
        storage: TestTokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = adapter,
      ),
    ).batches;
  });

  test(
    'admits ordered queries against NestJS with the authenticated replay key',
    () async {
      adapter.response = envelope(batch);
      adapter.status = 202;
      final result = await api.create('campaign', const [
        BatchQuery('Café', 'Tijuana', 150),
        BatchQuery('Taller', 'Rosarito', 1),
      ], 'fixture-replay-key');
      expect(result.admission, BatchAdmission.UNCERTAIN);
      expect(result.jobs.single.state, isNull);
      expect(result.jobs.single.confirmation?.ackAt, isNull);
      expect(adapter.request!.path, '/api/v1/prospecting-batches');
      expect(adapter.request!.headers['Authorization'], 'Bearer token');
      expect(adapter.request!.headers['Idempotency-Key'], 'fixture-replay-key');
      expect(adapter.request!.data, {
        'campaignId': 'campaign',
        'queries': [
          {
            'source': 'google_maps',
            'keyword': 'Café',
            'location': 'Tijuana',
            'limit': 150,
          },
          {
            'source': 'google_maps',
            'keyword': 'Taller',
            'location': 'Rosarito',
            'limit': 1,
          },
        ],
      });
    },
  );

  test(
    'identifies a partial snapshot and posts human decisions without row payloads',
    () async {
      adapter.response = envelope({
        'snapshotId': 'fixture-snapshot',
        'expiresAt': stamp,
        'quality': 'PARTIAL',
        'rows': [
          {
            'index': 0,
            'row': {'name': 'Verified business'},
            'blocked': false,
            'strongProspect': {'id': 'candidate', 'name': 'Shared master'},
            'candidates': [],
          },
          {
            'index': 1,
            'row': {'name': 'Collision'},
            'blocked': true,
          },
        ],
      });
      final review = await api.preview('batch', 'job');
      expect(review.quality, BatchQuality.PARTIAL);
      expect(review.rows[0].strongProspect?.id, 'candidate');
      expect(review.rows[1].blocked, isTrue);
      adapter.response = envelope(receipt);
      await api.confirm('batch', 'job', review.snapshotId, const [
        BatchRowDecision(
          0,
          BatchReviewAction.UPDATE_EXISTING,
          candidateId: 'candidate',
        ),
        BatchRowDecision(1, BatchReviewAction.SKIP),
      ]);
      expect(
        adapter.request!.path,
        '/api/v1/prospecting-batches/batch/jobs/job/confirm',
      );
      expect(adapter.request!.data, {
        'snapshotId': 'fixture-snapshot',
        'decisions': [
          {
            'index': 0,
            'action': 'UPDATE_EXISTING',
            'candidateId': 'candidate',
            'confirmSharedUpdate': true,
          },
          {'index': 1, 'action': 'SKIP'},
        ],
      });
      await api.settle('batch', 'job', review.snapshotId);
      expect(
        adapter.request!.path,
        endsWith('/confirmations/fixture-snapshot/settle'),
      );
      expect(adapter.request!.data, isNull);
    },
  );
}
