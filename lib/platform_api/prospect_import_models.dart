// ignore_for_file: constant_identifier_names
import 'models.dart';
import 'src/json_fields.dart';

enum ProspectImportClassification { NEW, MATCH, INVALID, CONFLICT }

enum ProspectImportAction { CREATE, LINK_EXISTING, UPDATE_EXISTING, SKIP }

enum ProspectImportResultAction {
  CREATE,
  LINK_EXISTING,
  UPDATE_EXISTING,
  SKIP,
  REJECTED
}

class ProspectImportDecision {
  const ProspectImportDecision({required this.record, required this.action});
  final int record;
  final ProspectImportAction action;
  Map<String, dynamic> toJson() => {'record': record, 'action': action.name};
}

List<T> _list<T>(Map<String, dynamic> json, String key,
        T Function(Map<String, dynamic>) parse) =>
    List.unmodifiable(requiredValue<List<dynamic>>(json, key)
        .map((v) => parse(jsonObject(v))));

class ProspectImportValues {
  ProspectImportValues.fromJson(Map<String, dynamic> json)
      : name = requiredValue<String>(json, 'name'),
        category = optionalValue<String>(json, 'category'),
        address = optionalValue<String>(json, 'address'),
        phone = optionalValue<String>(json, 'phone'),
        email = optionalValue<String>(json, 'email'),
        website = optionalValue<String>(json, 'website'),
        language = optionalValue<String>(json, 'language'),
        status = json['status'] == null
            ? null
            : enumValue(json['status'], ProspectStatus.values),
        presentFields = Set.unmodifiable(json.keys);
  final String name;
  final String? category;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? language;
  final ProspectStatus? status;
  final Set<String> presentFields;
}

class ProspectImportError {
  ProspectImportError.fromJson(Map<String, dynamic> json)
      : field = requiredValue<String>(json, 'field'),
        message = requiredValue<String>(json, 'message');
  final String field;
  final String message;
}

class ProspectImportDifference {
  ProspectImportDifference.fromJson(Map<String, dynamic> json)
      : field = requiredValue<String>(json, 'field'),
        existing = nullableValue<String>(json, 'existing'),
        imported = nullableValue<String>(json, 'imported');
  final String field;
  final String? existing;
  final String? imported;
}

class ProspectImportMatch {
  ProspectImportMatch.fromJson(Map<String, dynamic> json)
      : id = requiredValue<String>(json, 'id'),
        campaignIds = List.unmodifiable(
            requiredValue<List<dynamic>>(json, 'campaignIds').map((v) {
          if (v is! String) throw const FormatException('Invalid campaign ID');
          return v;
        })),
        sharedWithOtherCampaigns =
            requiredValue<bool>(json, 'sharedWithOtherCampaigns'),
        differences =
            _list(json, 'differences', ProspectImportDifference.fromJson);
  final String id;
  final List<String> campaignIds;
  final bool sharedWithOtherCampaigns;
  final List<ProspectImportDifference> differences;
}

class ProspectImportRow {
  ProspectImportRow.fromJson(Map<String, dynamic> json)
      : record = requiredValue<int>(json, 'record'),
        classification = enumValue(
            json['classification'], ProspectImportClassification.values),
        values = ProspectImportValues.fromJson(jsonObject(json['values'])),
        errors = _list(json, 'errors', ProspectImportError.fromJson),
        matches = _list(json, 'matches', ProspectImportMatch.fromJson);
  final int record;
  final ProspectImportClassification classification;
  final ProspectImportValues values;
  final List<ProspectImportError> errors;
  final List<ProspectImportMatch> matches;
}

class ProspectImportSummary {
  ProspectImportSummary.fromJson(Map<String, dynamic> json)
      : total = requiredValue<int>(json, 'total'),
        newCount = requiredValue<int>(json, 'new'),
        matches = requiredValue<int>(json, 'matches'),
        invalid = requiredValue<int>(json, 'invalid'),
        conflicts = requiredValue<int>(json, 'conflicts');
  final int total;
  final int newCount;
  final int matches;
  final int invalid;
  final int conflicts;
}

class ProspectImportPreview {
  ProspectImportPreview.fromJson(Map<String, dynamic> json)
      : previewReference = requiredValue<String>(json, 'previewReference'),
        expiresAt = dateValue(json, 'expiresAt'),
        summary = ProspectImportSummary.fromJson(jsonObject(json['summary'])),
        rows = _list(json, 'rows', ProspectImportRow.fromJson);
  final String previewReference;
  final DateTime expiresAt;
  final ProspectImportSummary summary;
  final List<ProspectImportRow> rows;
}

class ProspectImportResultSummary {
  ProspectImportResultSummary.fromJson(Map<String, dynamic> json)
      : total = requiredValue<int>(json, 'total'),
        created = requiredValue<int>(json, 'created'),
        linked = requiredValue<int>(json, 'linked'),
        updated = requiredValue<int>(json, 'updated'),
        skipped = requiredValue<int>(json, 'skipped'),
        rejected = requiredValue<int>(json, 'rejected');
  final int total;
  final int created;
  final int linked;
  final int updated;
  final int skipped;
  final int rejected;
}

class ProspectImportResultRow {
  ProspectImportResultRow.fromJson(Map<String, dynamic> json)
      : record = requiredValue<int>(json, 'record'),
        action = enumValue(json['action'], ProspectImportResultAction.values),
        prospectId = optionalValue<String>(json, 'prospectId'),
        errors = json['errors'] == null
            ? const []
            : _list(json, 'errors', ProspectImportError.fromJson);
  final int record;
  final ProspectImportResultAction action;
  final String? prospectId;
  final List<ProspectImportError> errors;
}

class ProspectImportResult {
  ProspectImportResult.fromJson(Map<String, dynamic> json)
      : summary =
            ProspectImportResultSummary.fromJson(jsonObject(json['summary'])),
        rows = _list(json, 'rows', ProspectImportResultRow.fromJson);
  final ProspectImportResultSummary summary;
  final List<ProspectImportResultRow> rows;
}
