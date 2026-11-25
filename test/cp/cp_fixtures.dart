import 'package:saas_platform_client/platform_api/campaign_participation_api.dart';
import 'package:saas_platform_client/platform_api/prospect_context_api.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/features/campaigns/data/participation_repository.dart';
import 'package:saas_platform_client/features/prospects/data/prospect_context_repository.dart';
import '../features/prospects_fixtures.dart';
import '../platform_api/fixtures.dart';

final participationJson = {
  'campaignId': entityId,
  'prospectId': entityId,
  'status': 'ACTIVO',
  'commercialStage': 'SIN_GESTIONAR',
  'evaluation': 'SIN_EVALUAR',
  'responsibleId': null,
  'responsible': null,
  'addedAt': stamp,
  'updatedAt': stamp,
};

class FakeParticipation implements ParticipationRepository {
  int reads = 0;
  PaginationQuery? lastQuery;
  CampaignProspectFilters? lastFilters;
  Future<PaginatedResult<CampaignProspect>>? pending;
  Object? error;
  @override
  Future<PaginatedResult<CampaignProspect>> prospects(
    String campaign,
    PaginationQuery query,
    CampaignProspectFilters filters,
  ) async {
    reads++;
    lastQuery = query;
    lastFilters = filters;
    if (error != null) throw error!;
    if (pending != null) return pending!;
    return PaginatedResult(
      items: [
        CampaignProspect.fromJson({
          ...prospectJson,
          'participation': participationJson,
        }),
      ],
      meta: PaginationMeta(
        page: query.page ?? 1,
        limit: 20,
        total: 21,
        totalPages: 2,
      ),
    );
  }

  @override
  Future<CampaignDashboard> dashboard(String campaign) async =>
      CampaignDashboard.fromJson({
        'total': 1,
        'stages': {'SIN_GESTIONAR': 1},
        'evaluations': {'SIN_EVALUAR': 1},
        'responsibility': {'SIN_ASIGNAR': 1},
        'activity': {'total': 1, 'manual': 0, 'events': 1},
        'incorporation': {'new': 1, 'reused': 0, 'unknownLegacy': 0},
      });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProspectContext implements ProspectContextRepository {
  FakeProspectContext(this.repository);
  final FakeProspects repository;
  @override
  Future<ProspectMatch> match(ProspectIntakeRequest request) async =>
      ProspectMatch.fromJson({
        'strongProspect': null,
        'candidates': [],
        'resolutionRequired': false,
      });
  @override
  Future<Prospect> create(ProspectIntakeRequest request) =>
      repository.create(request.prospect);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
