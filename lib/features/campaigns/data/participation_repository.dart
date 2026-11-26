import '../../../platform_api/campaign_participation_api.dart';
import '../../../platform_api/platform_api.dart'
    show PaginationQuery, PaginatedResult;

class ParticipationRepository {
  const ParticipationRepository(this.api);
  final CampaignParticipationApi api;
  Future<PaginatedResult<CampaignProspect>> prospects(
    String campaign,
    PaginationQuery query,
    CampaignProspectFilters filters,
  ) => api.prospects(campaign, query: query, filters: filters);
  Future<CampaignDashboard> dashboard(String campaign) =>
      api.dashboard(campaign);
  Future<CampaignParticipation> get(String campaign, String prospect) =>
      api.get(campaign, prospect);
  Future<CampaignParticipation> stage(
    String campaign,
    String prospect,
    CommercialStage stage,
  ) => api.stage(campaign, prospect, stage);
  Future<CampaignParticipation> evaluate(
    String campaign,
    String prospect,
    CommercialEvaluation evaluation,
    String? reason,
  ) => api.evaluate(campaign, prospect, evaluation, reason: reason);
  Future<List<ParticipationResponsible>> responsibles(
    String campaign,
    String prospect,
  ) => api.responsibles(campaign, prospect);
  Future<CampaignParticipation> assign(
    String campaign,
    String prospect,
    String? responsibleId,
  ) => api.assign(campaign, prospect, responsibleId);
  Future<PaginatedResult<CampaignActivity>> activities(
    String campaign,
    String prospect,
    int page,
  ) => api.activities(campaign, prospect, page: page);
  Future<CampaignActivity> record(
    String campaign,
    String prospect, {
    required CampaignActivityType type,
    required String content,
    String? declaredAt,
    String? correctsId,
  }) => api.record(
    campaign,
    prospect,
    type: type,
    content: content,
    declaredAt: declaredAt,
    correctsId: correctsId,
  );
}
