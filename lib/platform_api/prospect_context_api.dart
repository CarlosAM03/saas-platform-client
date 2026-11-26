import '../core/network/api_client.dart';
import '../shared/models/api_models.dart'
    show unwrapObject, unwrapPaginated, PaginatedResult, PaginationMeta;
import 'models.dart';
import 'requests.dart';
import 'src/api_support.dart';
import 'src/json_fields.dart';
import 'campaign_participation_models.dart';

enum ProspectResolution { create, linkExisting, skip }

extension ProspectResolutionWire on ProspectResolution {
  String get wire => switch (this) {
    ProspectResolution.create => 'CREATE',
    ProspectResolution.linkExisting => 'LINK_EXISTING',
    ProspectResolution.skip => 'SKIP',
  };
}

class ProspectIntakeRequest {
  const ProspectIntakeRequest(this.prospect, {this.identityIdentifier});
  final CreateProspectRequest prospect;
  final String? identityIdentifier;
  Map<String, dynamic> toJson() => {
    ...prospect.toJson(),
    if (identityIdentifier != null) ...{
      'identitySource': 'google_maps',
      'identityIdentifier': identityIdentifier,
    },
  };
}

class ProspectMatch {
  ProspectMatch.fromJson(Map<String, dynamic> json)
    : strongProspect = json['strongProspect'] == null
          ? null
          : Prospect.fromJson(jsonObject(json['strongProspect'])),
      candidates = List.unmodifiable(
        requiredValue<List<dynamic>>(
          json,
          'candidates',
        ).map((e) => Prospect.fromJson(jsonObject(e))),
      ),
      resolutionRequired = requiredValue<bool>(json, 'resolutionRequired');
  final Prospect? strongProspect;
  final List<Prospect> candidates;
  final bool resolutionRequired;
}

class ProspectResolutionResult {
  ProspectResolutionResult.fromJson(Map<String, dynamic> json)
    : action = ProspectResolution.values.firstWhere(
        (e) => e.wire == json['action'],
      ),
      prospect = json['prospect'] == null
          ? null
          : Prospect.fromJson(jsonObject(json['prospect']));
  final ProspectResolution action;
  final Prospect? prospect;
}

class AssociatedCampaign {
  AssociatedCampaign.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(jsonObject(json['campaign']), 'id'),
      name = requiredValue<String>(jsonObject(json['campaign']), 'name'),
      status = enumValue(
        jsonObject(json['campaign'])['status'],
        CampaignStatus.values,
      ),
      isOrigin = requiredValue<bool>(json, 'isOrigin'),
      stage = enumValue(json['stage'], CommercialStage.values),
      evaluation = enumValue(json['evaluation'], CommercialEvaluation.values),
      responsible = json['responsible'] == null
          ? null
          : ParticipationResponsible.fromJson(jsonObject(json['responsible'])),
      latestActivity = json['latestActivity'] == null
          ? null
          : CampaignActivity.fromJson(jsonObject(json['latestActivity'])),
      addedAt = dateValue(json, 'addedAt');
  final String id, name;
  final CampaignStatus status;
  final bool isOrigin;
  final CommercialStage stage;
  final CommercialEvaluation evaluation;
  final ParticipationResponsible? responsible;
  final CampaignActivity? latestActivity;
  final DateTime addedAt;
}

enum ProvenanceType { created, linked, reappeared, masterUpdated }

class ProspectProvenance {
  ProspectProvenance.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(json, 'id'),
      type = switch (json['type']) {
        'CREATED' => ProvenanceType.created,
        'LINKED' => ProvenanceType.linked,
        'REAPPEARED' => ProvenanceType.reappeared,
        'MASTER_UPDATED' => ProvenanceType.masterUpdated,
        _ => throw const FormatException('Unknown provenance type'),
      },
      source = requiredValue<String>(json, 'source'),
      campaignId = optionalValue<String>(json, 'campaignId'),
      actorName = json['actor'] == null
          ? null
          : optionalValue<String>(jsonObject(json['actor']), 'name'),
      recordedAt = dateValue(json, 'recordedAt');
  final String id, source;
  final ProvenanceType type;
  final String? campaignId, actorName;
  final DateTime recordedAt;
}

class ProspectContextApi {
  const ProspectContextApi(this.client);
  final ApiClient client;
  Future<ProspectMatch> match(ProspectIntakeRequest request) async =>
      ProspectMatch.fromJson(
        unwrapObject(
          await client.post('/api/v1/prospects/match', data: request.toJson()),
        ),
      );
  Future<Prospect> create(ProspectIntakeRequest request) async =>
      Prospect.fromJson(
        unwrapObject(
          await client.post('/api/v1/prospects', data: request.toJson()),
        ),
      );
  Future<ProspectResolutionResult> resolve(
    ProspectIntakeRequest request,
    ProspectResolution resolution, {
    String? candidateId,
  }) async => ProspectResolutionResult.fromJson(
    unwrapObject(
      await client.post(
        '/api/v1/prospects/resolve',
        data: {
          ...request.toJson(),
          'resolution': resolution.wire,
          if (candidateId != null) 'candidateId': candidateId,
        },
      ),
    ),
  );
  Future<PaginatedResult<AssociatedCampaign>> campaigns(
    String prospect,
    int page,
  ) async {
    final data = unwrapObject(
      await client.get(
        '${entityPath('prospects', prospect)}/campaigns',
        queryParameters: {'page': page, 'limit': 20},
      ),
    );
    return PaginatedResult(
      items: List.unmodifiable(
        requiredValue<List<dynamic>>(
          data,
          'campaigns',
        ).map((e) => AssociatedCampaign.fromJson(jsonObject(e))),
      ),
      meta: PaginationMeta.fromJson(jsonObject(data['meta'])),
    );
  }

  Future<PaginatedResult<ProspectProvenance>> provenance(
    String prospect,
    int page,
  ) async => unwrapPaginated(
    await client.get(
      '${entityPath('prospects', prospect)}/provenance',
      queryParameters: {'page': page, 'limit': 20},
    ),
    ProspectProvenance.fromJson,
  );
  Future<Prospect> update(
    String prospect,
    UpdateProspectRequest request, {
    String? contextCampaignId,
  }) async => Prospect.fromJson(
    unwrapObject(
      await client.patch(
        entityPath('prospects', prospect),
        data: {
          ...request.toJson(),
          if (contextCampaignId != null) 'contextCampaignId': contextCampaignId,
        },
      ),
    ),
  );
}
