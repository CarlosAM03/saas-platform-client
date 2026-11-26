// ignore_for_file: constant_identifier_names
import 'models.dart';
import 'src/json_fields.dart';

enum CommercialStage {
  SIN_GESTIONAR,
  EN_INVESTIGACION,
  CONTACTADO,
  EN_SEGUIMIENTO,
  OPORTUNIDAD,
  CERRADO,
}

enum CommercialEvaluation { SIN_EVALUAR, APTO, NO_APTO }

enum CampaignActivityType {
  NOTE,
  CALL,
  EMAIL,
  MEETING,
  OTHER,
  ASSOCIATION,
  STAGE_CHANGE,
  EVALUATION_CHANGE,
  RESPONSIBLE_CHANGE,
  CORRECTION,
  MASTER_UPDATE,
}

const manualActivityTypes = [
  CampaignActivityType.NOTE,
  CampaignActivityType.CALL,
  CampaignActivityType.EMAIL,
  CampaignActivityType.MEETING,
  CampaignActivityType.OTHER,
];

class ParticipationResponsible {
  ParticipationResponsible.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(json, 'id'),
      name = requiredValue<String>(json, 'name'),
      eligible = requiredValue<bool>(json, 'eligible');
  final String id, name;
  final bool eligible;
}

class CampaignParticipation {
  CampaignParticipation.fromJson(Map<String, dynamic> json)
    : campaignId = requiredValue<String>(json, 'campaignId'),
      prospectId = requiredValue<String>(json, 'prospectId'),
      stage = enumValue(json['commercialStage'], CommercialStage.values),
      evaluation = enumValue(json['evaluation'], CommercialEvaluation.values),
      evaluationReason = optionalValue<String>(json, 'evaluationReason'),
      responsibleId = nullableValue<String>(json, 'responsibleId'),
      responsible = json['responsible'] == null
          ? null
          : ParticipationResponsible.fromJson(jsonObject(json['responsible'])),
      addedAt = dateValue(json, 'addedAt'),
      updatedAt = dateValue(json, 'updatedAt');
  final String campaignId, prospectId;
  final CommercialStage stage;
  final CommercialEvaluation evaluation;
  final String? evaluationReason, responsibleId;
  final ParticipationResponsible? responsible;
  final DateTime addedAt, updatedAt;
}

class CampaignProspect {
  CampaignProspect.fromJson(Map<String, dynamic> json)
    : prospect = Prospect.fromJson(json),
      participation = CampaignParticipation.fromJson(
        jsonObject(json['participation']),
      );
  final Prospect prospect;
  final CampaignParticipation participation;
}

class CampaignActivity {
  CampaignActivity.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(json, 'id'),
      type = enumValue(json['type'], CampaignActivityType.values),
      content = optionalValue<String>(json, 'content'),
      actorName = json['actor'] == null
          ? null
          : optionalValue<String>(jsonObject(json['actor']), 'name'),
      recordedAt = dateValue(json, 'recordedAt'),
      declaredAt = json['declaredAt'] == null
          ? null
          : dateValue(json, 'declaredAt'),
      correctsId = optionalValue<String>(json, 'correctsId'),
      previousValue = optionalValue<String>(json, 'previousValue'),
      newValue = optionalValue<String>(json, 'newValue'),
      reason = optionalValue<String>(json, 'reason');
  final String id;
  final CampaignActivityType type;
  final String? content, actorName, correctsId, previousValue, newValue, reason;
  final DateTime recordedAt;
  final DateTime? declaredAt;
  bool get isManual =>
      manualActivityTypes.contains(type) ||
      type == CampaignActivityType.CORRECTION;
}

Map<String, int> _counts(Object? value) => Map.unmodifiable(
  jsonObject(value).map((key, value) {
    if (value is! int) throw const FormatException('Invalid dashboard count');
    return MapEntry(key, value);
  }),
);

class CampaignDashboard {
  CampaignDashboard.fromJson(Map<String, dynamic> json)
    : total = requiredValue<int>(json, 'total'),
      stages = _counts(json['stages']),
      evaluations = _counts(json['evaluations']),
      responsibility = _counts(json['responsibility']),
      activityTotal = requiredValue<int>(jsonObject(json['activity']), 'total'),
      manual = requiredValue<int>(jsonObject(json['activity']), 'manual'),
      events = requiredValue<int>(jsonObject(json['activity']), 'events'),
      newCount = requiredValue<int>(jsonObject(json['incorporation']), 'new'),
      reused = requiredValue<int>(jsonObject(json['incorporation']), 'reused'),
      unknownLegacy = requiredValue<int>(
        jsonObject(json['incorporation']),
        'unknownLegacy',
      );
  final int total,
      activityTotal,
      manual,
      events,
      newCount,
      reused,
      unknownLegacy;
  final Map<String, int> stages, evaluations, responsibility;
}

class CampaignProspectFilters {
  const CampaignProspectFilters({
    this.search,
    this.category,
    this.address,
    this.source,
    this.stage,
    this.evaluation,
    this.responsibleId,
    this.addedFrom,
    this.addedTo,
    this.activityFrom,
    this.activityTo,
  });
  final String? search,
      category,
      address,
      source,
      responsibleId,
      addedFrom,
      addedTo,
      activityFrom,
      activityTo;
  final CommercialStage? stage;
  final CommercialEvaluation? evaluation;
  Map<String, dynamic> toQuery() => {
    if (search != null && search!.isNotEmpty) 'search': search,
    if (category != null && category!.isNotEmpty) 'category': category,
    if (address != null && address!.isNotEmpty) 'address': address,
    if (source != null && source!.isNotEmpty) 'source': source,
    if (responsibleId != null && responsibleId!.isNotEmpty)
      'responsibleId': responsibleId,
    if (stage != null) 'stage': stage!.name,
    if (evaluation != null) 'evaluation': evaluation!.name,
    if (addedFrom != null && addedFrom!.isNotEmpty) 'addedFrom': addedFrom,
    if (addedTo != null && addedTo!.isNotEmpty) 'addedTo': addedTo,
    if (activityFrom != null && activityFrom!.isNotEmpty)
      'activityFrom': activityFrom,
    if (activityTo != null && activityTo!.isNotEmpty) 'activityTo': activityTo,
  };
}
