import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/campaign_participation_api.dart';
import 'package:saas_platform_client/platform_api/prospect_context_api.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../platform_api/fixtures.dart';

final participation = {
  'campaignId': 'c',
  'prospectId': 'p',
  'status': 'ACTIVO',
  'commercialStage': 'CONTACTADO',
  'evaluation': 'NO_APTO',
  'evaluationReason': 'Synthetic reason',
  'responsibleId': 'u',
  'responsible': {'id': 'u', 'name': 'Synthetic member', 'eligible': false},
  'addedAt': stamp,
  'updatedAt': stamp,
};
final activity = {
  'id': 'a',
  'type': 'CORRECTION',
  'content': 'Correction',
  'recordedAt': stamp,
  'declaredAt': stamp,
  'correctsId': 'original',
};
final dashboard = {
  'total': 2,
  'stages': {'CONTACTADO': 2},
  'evaluations': {'NO_APTO': 2},
  'responsibility': {'SIN_ASIGNAR': 2},
  'activity': {'total': 5, 'manual': 2, 'events': 3},
  'incorporation': {'new': 1, 'reused': 1, 'unknownLegacy': 0},
};
ApiClient client(
  ContractAdapter adapter, {
  TestTokenStorage? storage,
  Future<void> Function()? unauthorized,
}) => ApiClient(
  config: const AppConfig(apiBaseUrl: 'http://localhost'),
  storage: storage ?? TestTokenStorage(),
  onUnauthorized: unauthorized,
  dio: Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = adapter,
);

void main() {
  test(
    'participation parses context without changing the shared master model',
    () {
      final row = CampaignProspect.fromJson({
        ...prospectJson,
        'participation': participation,
      });
      expect(row.prospect.status, ProspectStatus.ACTIVO);
      expect(row.participation.stage, CommercialStage.CONTACTADO);
      expect(row.participation.evaluationReason, 'Synthetic reason');
      expect(row.participation.responsible!.eligible, false);
      expect(
        () => CampaignParticipation.fromJson({
          ...participation,
          'commercialStage': 'ACTIVO',
        }),
        throwsFormatException,
      );
    },
  );
  test('CORRECTION is manual; automatic types cannot be submitted', () async {
    expect(CampaignActivity.fromJson(activity).isManual, true);
    expect(
      CampaignActivity.fromJson({...activity, 'type': 'STAGE_CHANGE'}).isManual,
      false,
    );
    final adapter = ContractAdapter()..response = envelope(activity);
    final api = CampaignParticipationApi(client(adapter));
    await api.record(
      'c',
      'p',
      type: CampaignActivityType.CALL,
      content: 'Correction',
      correctsId: 'original',
      declaredAt: stamp,
    );
    expect(adapter.request!.data, {
      'type': 'CALL',
      'content': 'Correction',
      'correctsId': 'original',
      'declaredAt': stamp,
    });
    await expectLater(
      api.record(
        'c',
        'p',
        type: CampaignActivityType.MASTER_UPDATE,
        content: 'No',
      ),
      throwsArgumentError,
    );
    expect(adapter.request!.method, 'POST');
  });
  test('all C6 dimensions are sent together with server pagination', () async {
    final adapter = ContractAdapter()
      ..response = page({...prospectJson, 'participation': participation});
    final api = CampaignParticipationApi(client(adapter));
    final result = await api.prospects(
      'c',
      query: const PaginationQuery(
        page: 2,
        limit: 5,
        sortBy: SortField.email,
        sortOrder: SortOrder.desc,
      ),
      filters: const CampaignProspectFilters(
        search: 'Alpha',
        category: 'Cafe',
        address: 'North',
        source: 'csv',
        stage: CommercialStage.CONTACTADO,
        evaluation: CommercialEvaluation.APTO,
        responsibleId: 'UNASSIGNED',
        addedFrom: stamp,
        addedTo: stamp,
        activityFrom: stamp,
        activityTo: stamp,
      ),
    );
    expect(adapter.request!.queryParameters, {
      'page': 2,
      'limit': 5,
      'sortBy': 'email',
      'sortOrder': 'desc',
      'search': 'Alpha',
      'category': 'Cafe',
      'address': 'North',
      'source': 'csv',
      'stage': 'CONTACTADO',
      'evaluation': 'APTO',
      'responsibleId': 'UNASSIGNED',
      'addedFrom': stamp,
      'addedTo': stamp,
      'activityFrom': stamp,
      'activityTo': stamp,
    });
    expect(result.meta.total, 6);
  });
  test('dashboard keeps the values from a single server response', () async {
    final adapter = ContractAdapter()..response = envelope(dashboard);
    final data = await CampaignParticipationApi(client(adapter)).dashboard('c');
    expect(data.manual, 2);
    expect(data.events, 3);
    expect(data.activityTotal, 5);
    expect(data.total, 2);
    expect(data.newCount, 1);
    expect(data.reused, 1);
    expect(adapter.request!.path, '/api/v1/campaigns/c/dashboard');
    expect(
      () => CampaignDashboard.fromJson({...dashboard, 'activity': {}}),
      throwsFormatException,
    );
  });
  test(
    'stage, evaluation, responsibilities and activity pagination follow the contract',
    () async {
      final adapter = ContractAdapter()..response = envelope(participation);
      final api = CampaignParticipationApi(client(adapter));
      await api.get('c', 'p');
      expect(
        adapter.request!.path,
        '/api/v1/campaigns/c/prospects/p/participation',
      );
      await api.stage('c', 'p', CommercialStage.CERRADO);
      expect(adapter.request!.data, {'stage': 'CERRADO'});
      await api.evaluate(
        'c',
        'p',
        CommercialEvaluation.NO_APTO,
        reason: 'Synthetic',
      );
      expect(adapter.request!.data, {
        'evaluation': 'NO_APTO',
        'reason': 'Synthetic',
      });
      await api.assign('c', 'p', 'u');
      expect(adapter.request!.method, 'PUT');
      expect(adapter.request!.data, {'responsibleId': 'u'});
      expect(adapter.request!.headers['Authorization'], 'Bearer token');
      await api.assign('c', 'p', null);
      expect(adapter.request!.method, 'DELETE');
      adapter.response = envelope([
        {'id': 'u', 'name': 'Synthetic', 'eligible': true},
      ]);
      expect((await api.responsibles('c', 'p')).single.eligible, true);
      adapter.response = page(activity);
      expect(
        (await api.activities('c', 'p', page: 2)).items.single.correctsId,
        'original',
      );
      expect(adapter.request!.queryParameters, {'page': 2, 'limit': 20});
    },
  );
  for (final status in [400, 401, 403, 404, 409]) {
    test(
      'PUT preserves server $status and invalidates only a current 401',
      () async {
        final storage = TestTokenStorage();
        var unauthorized = 0;
        final adapter = ContractAdapter()
          ..response = apiError(status)
          ..status = status;
        final api = CampaignParticipationApi(
          client(
            adapter,
            storage: storage,
            unauthorized: () async {
              unauthorized++;
            },
          ),
        );
        await expectLater(
          api.assign('c', 'p', 'u'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', status)
                .having((e) => e.message, 'message', 'Rejected'),
          ),
        );
        expect(unauthorized, status == 401 ? 1 : 0);
        expect(storage.token, status == 401 ? null : 'token');
      },
    );
  }
  test(
    'P1 verifies before explicit resolution and keeps the external identity',
    () async {
      final adapter = ContractAdapter()
        ..response = envelope({
          'strongProspect': null,
          'candidates': [prospectJson],
          'resolutionRequired': true,
        });
      final api = ProspectContextApi(client(adapter));
      const request = ProspectIntakeRequest(
        CreateProspectRequest(campaignId: 'c', name: 'Synthetic'),
        identityIdentifier: 'Place-Case',
      );
      expect((await api.match(request)).resolutionRequired, true);
      expect(adapter.request!.path, '/api/v1/prospects/match');
      expect(adapter.request!.data['identityIdentifier'], 'Place-Case');
      adapter.response = envelope({
        'action': 'LINK_EXISTING',
        'prospect': prospectJson,
      });
      expect(
        (await api.resolve(
          request,
          ProspectResolution.linkExisting,
          candidateId: 'p',
        )).prospect!.id,
        entityId,
      );
      expect(adapter.request!.data['candidateId'], 'p');
      expect(adapter.request!.data['resolution'], 'LINK_EXISTING');
    },
  );
  test('P2 nested metadata and P3 envelope metadata are distinct', () async {
    final adapter = ContractAdapter()
      ..response = envelope({
        'originCampaignId': 'c',
        'meta': {'page': 2, 'limit': 20, 'total': 22, 'totalPages': 2},
        'campaigns': [
          {
            'campaign': {'id': 'c', 'name': 'Synthetic', 'status': 'ACTIVA'},
            'isOrigin': true,
            'stage': 'CONTACTADO',
            'evaluation': 'APTO',
            'responsible': null,
            'latestActivity': activity,
            'addedAt': stamp,
          },
        ],
      });
    final api = ProspectContextApi(client(adapter));
    final campaigns = await api.campaigns('p', 2);
    expect(campaigns.meta.total, 22);
    expect(campaigns.items.single.isOrigin, true);
    adapter.response = page({
      'id': 'e',
      'type': 'MASTER_UPDATED',
      'source': 'manual',
      'campaignId': 'c',
      'recordedAt': stamp,
    });
    expect(
      (await api.provenance('p', 2)).items.single.type,
      ProvenanceType.masterUpdated,
    );
    adapter.response = envelope(prospectJson);
    await api.update(
      'p',
      const UpdateProspectRequest(name: 'New name'),
      contextCampaignId: 'c',
    );
    expect(adapter.request!.data, {
      'name': 'New name',
      'contextCampaignId': 'c',
    });
  });
}
