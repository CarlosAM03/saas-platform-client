import '../core/network/api_client.dart';
import '../shared/models/api_models.dart'
    show unwrapObject, unwrapList, unwrapPaginated, PaginatedResult;
import 'campaign_participation_models.dart';
import 'pagination_query.dart';
import 'src/api_support.dart';

export 'campaign_participation_models.dart';

class CampaignParticipationApi {
  const CampaignParticipationApi(this._client);
  final ApiClient _client;
  String _campaign(String id) => entityPath('campaigns', id);
  String _participation(String campaign, String prospect) =>
      '${_campaign(campaign)}/prospects/${Uri.encodeComponent(prospect)}';
  Future<PaginatedResult<CampaignProspect>> prospects(
    String campaign, {
    PaginationQuery query = const PaginationQuery(),
    CampaignProspectFilters filters = const CampaignProspectFilters(),
  }) async => unwrapPaginated(
    await _client.get(
      '${_campaign(campaign)}/prospects',
      queryParameters: {
        ...query.toQuery(allowedSorts: commonSorts),
        ...filters.toQuery(),
      },
    ),
    CampaignProspect.fromJson,
  );
  Future<CampaignDashboard> dashboard(String campaign) async =>
      CampaignDashboard.fromJson(
        unwrapObject(await _client.get('${_campaign(campaign)}/dashboard')),
      );
  Future<CampaignParticipation> get(String campaign, String prospect) async =>
      CampaignParticipation.fromJson(
        unwrapObject(
          await _client.get(
            '${_participation(campaign, prospect)}/participation',
          ),
        ),
      );
  Future<CampaignParticipation> stage(
    String campaign,
    String prospect,
    CommercialStage stage,
  ) async => CampaignParticipation.fromJson(
    unwrapObject(
      await _client.patch(
        '${_participation(campaign, prospect)}/stage',
        data: {'stage': stage.name},
      ),
    ),
  );
  Future<CampaignParticipation> evaluate(
    String campaign,
    String prospect,
    CommercialEvaluation evaluation, {
    String? reason,
  }) async => CampaignParticipation.fromJson(
    unwrapObject(
      await _client.patch(
        '${_participation(campaign, prospect)}/evaluation',
        data: {
          'evaluation': evaluation.name,
          if (reason != null) 'reason': reason,
        },
      ),
    ),
  );
  Future<List<ParticipationResponsible>> responsibles(
    String campaign,
    String prospect,
  ) async => unwrapList(
    await _client.get('${_participation(campaign, prospect)}/responsibles'),
    ParticipationResponsible.fromJson,
  );
  Future<CampaignParticipation> assign(
    String campaign,
    String prospect,
    String? responsibleId,
  ) async => CampaignParticipation.fromJson(
    unwrapObject(
      responsibleId == null
          ? await _client.delete(
              '${_participation(campaign, prospect)}/responsible',
            )
          : await _client.put(
              '${_participation(campaign, prospect)}/responsible',
              data: {'responsibleId': responsibleId},
            ),
    ),
  );
  Future<PaginatedResult<CampaignActivity>> activities(
    String campaign,
    String prospect, {
    int page = 1,
  }) async => unwrapPaginated(
    await _client.get(
      '${_participation(campaign, prospect)}/activities',
      queryParameters: PaginationQuery(page: page, limit: 20).toQuery(),
    ),
    CampaignActivity.fromJson,
  );
  Future<CampaignActivity> record(
    String campaign,
    String prospect, {
    required CampaignActivityType type,
    required String content,
    String? declaredAt,
    String? correctsId,
  }) async {
    if (!manualActivityTypes.contains(type)) {
      throw ArgumentError('Only manual activity types may be submitted');
    }
    return CampaignActivity.fromJson(
      unwrapObject(
        await _client.post(
          '${_participation(campaign, prospect)}/activities',
          data: {
            'type': type.name,
            'content': content,
            if (declaredAt != null) 'declaredAt': declaredAt,
            if (correctsId != null) 'correctsId': correctsId,
          },
        ),
      ),
    );
  }
}
