// The enumerators match the versioned NestJS JSON values.
// ignore_for_file: constant_identifier_names

import '../core/network/api_client.dart';
import '../core/network/api_download.dart';
import '../shared/models/api_models.dart';
import 'src/api_support.dart';
import 'src/json_fields.dart';

const _resource = 'prospecting-batches';

enum BatchAdmission { PENDING, ACCEPTED, UNCERTAIN, REJECTED }

enum BatchJobState {
  QUEUED,
  RUNNING,
  AWAITING_RESULTS,
  COMPLETED,
  FAILED,
  INTERRUPTED,
  SKIPPED,
}

enum BatchAvailability { AVAILABLE, EXPIRED, PURGED, UNAVAILABLE }

enum BatchQuality { SUCCESS, SUCCESS_WITH_ISSUES, PARTIAL }

enum BatchReviewAction { CREATE, LINK_EXISTING, UPDATE_EXISTING, SKIP }

enum BatchExportFormat { csv, xlsx }

class BatchQuery {
  const BatchQuery(this.keyword, this.location, this.limit);

  final String keyword;
  final String location;
  final int limit;

  Map<String, Object> toJson() => {
    'source': 'google_maps',
    'keyword': keyword,
    'location': location,
    'limit': limit,
  };
}

class BatchSummary {
  BatchSummary.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(json, 'id'),
      campaignId = requiredValue<String>(json, 'campaignId'),
      admission = enumValue(json['admission'], BatchAdmission.values),
      createdAt = dateValue(json, 'createdAt'),
      remoteObserved = optionalValue<bool>(json, 'remoteObserved'),
      jobs = List.unmodifiable(
        requiredValue<List<Object?>>(
          json,
          'jobs',
        ).map((row) => BatchJobSummary.fromJson(jsonObject(row))),
      );

  final String id;
  final String campaignId;
  final BatchAdmission admission;
  final DateTime createdAt;
  final bool? remoteObserved;
  final List<BatchJobSummary> jobs;
}

class BatchJobSummary {
  BatchJobSummary.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(json, 'id'),
      position = requiredValue<int>(json, 'position'),
      state = _nullableEnum(json, 'state', BatchJobState.values),
      availability = _nullableEnum(
        json,
        'availability',
        BatchAvailability.values,
      ),
      progress = json['progress'] == null ? null : jsonObject(json['progress']),
      confirmation = json['confirmation'] == null
          ? null
          : BatchReviewReceipt.fromJson(jsonObject(json['confirmation']));

  final String id;
  final int position;
  final BatchJobState? state;
  final BatchAvailability? availability;
  final Map<String, dynamic>? progress;
  final BatchReviewReceipt? confirmation;
}

T? _nullableEnum<T extends Enum>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
) {
  final value = nullableValue<String>(json, key);
  return value == null ? null : enumValue(value, values);
}

class BatchReview {
  BatchReview.fromJson(Map<String, dynamic> json)
    : snapshotId = requiredValue<String>(json, 'snapshotId'),
      expiresAt = dateValue(json, 'expiresAt'),
      quality = enumValue(json['quality'], BatchQuality.values),
      rows = List.unmodifiable(
        requiredValue<List<Object?>>(
          json,
          'rows',
        ).map((row) => BatchReviewRow.fromJson(jsonObject(row))),
      );

  final String snapshotId;
  final DateTime expiresAt;
  final BatchQuality quality;
  final List<BatchReviewRow> rows;
}

class BatchReviewRow {
  BatchReviewRow.fromJson(Map<String, dynamic> json)
    : index = requiredValue<int>(json, 'index'),
      blocked = requiredValue<bool>(json, 'blocked'),
      name = requiredValue<String>(jsonObject(json['row']), 'name'),
      address = optionalValue<String>(jsonObject(json['row']), 'address'),
      phone = optionalValue<String>(jsonObject(json['row']), 'phone'),
      website = optionalValue<String>(jsonObject(json['row']), 'website'),
      strongProspect = json['strongProspect'] == null
          ? null
          : BatchCandidate.fromJson(jsonObject(json['strongProspect'])),
      candidates = List.unmodifiable(
        (optionalValue<List<Object?>>(json, 'candidates') ?? const []).map(
          (row) => BatchCandidate.fromJson(jsonObject(row)),
        ),
      );

  final int index;
  final bool blocked;
  final String name;
  final String? address;
  final String? phone;
  final String? website;
  final BatchCandidate? strongProspect;
  final List<BatchCandidate> candidates;
}

class BatchCandidate {
  BatchCandidate.fromJson(Map<String, dynamic> json)
    : id = requiredValue<String>(json, 'id'),
      name = requiredValue<String>(json, 'name'),
      address = optionalValue<String>(json, 'address');

  final String id;
  final String name;
  final String? address;
}

class BatchRowDecision {
  const BatchRowDecision(this.index, this.action, {this.candidateId});

  final int index;
  final BatchReviewAction action;
  final String? candidateId;

  Map<String, Object> toJson() => {
    'index': index,
    'action': action.name,
    if (candidateId != null) 'candidateId': candidateId!,
    if (action == BatchReviewAction.UPDATE_EXISTING)
      'confirmSharedUpdate': true,
  };
}

class BatchReviewReceipt {
  BatchReviewReceipt.fromJson(Map<String, dynamic> json)
    : snapshotId = requiredValue<String>(json, 'snapshotId'),
      processedCount = requiredValue<int>(json, 'processedCount'),
      omittedCount = requiredValue<int>(json, 'omittedCount'),
      ackAt = nullableDate(json, 'ackAt'),
      purgedAt = nullableDate(json, 'purgedAt');

  final String snapshotId;
  final int processedCount;
  final int omittedCount;
  final DateTime? ackAt;
  final DateTime? purgedAt;
}

class ProspectingBatchesApi {
  const ProspectingBatchesApi(this._client);
  final ApiClient _client;

  String _job(String batch, String job) =>
      '${entityPath(_resource, batch)}/jobs/${Uri.encodeComponent(job)}';

  Future<BatchSummary> create(
    String campaign,
    List<BatchQuery> queries,
    String key,
  ) async => BatchSummary.fromJson(
    unwrapObject(
      await _client.post(
        '/api/v1/$_resource',
        headers: {'Idempotency-Key': key},
        data: {
          'campaignId': campaign,
          'queries': queries.map((query) => query.toJson()).toList(),
        },
      ),
    ),
  );

  Future<PaginatedResult<BatchSummary>> list(int page) async => unwrapPaginated(
    await _client.get(
      '/api/v1/$_resource',
      queryParameters: {'page': page, 'limit': 20},
    ),
    BatchSummary.fromJson,
  );

  Future<BatchSummary> reconcile(String batch) async => BatchSummary.fromJson(
    unwrapObject(
      await _client.post('${entityPath(_resource, batch)}/reconcile'),
    ),
  );

  Future<BatchReview> preview(String batch, String job) async =>
      BatchReview.fromJson(
        unwrapObject(await _client.get('${_job(batch, job)}/results')),
      );

  Future<ApiDownload> export(
    String batch,
    String job,
    BatchExportFormat format,
  ) => _client.downloadBytes(
    '${_job(batch, job)}/export',
    queryParameters: {'format': format.name},
  );

  Future<BatchReviewReceipt> confirm(
    String batch,
    String job,
    String snapshotId,
    List<BatchRowDecision> decisions,
  ) async => BatchReviewReceipt.fromJson(
    unwrapObject(
      await _client.post(
        '${_job(batch, job)}/confirm',
        data: {
          'snapshotId': snapshotId,
          'decisions': decisions.map((item) => item.toJson()).toList(),
        },
      ),
    ),
  );

  Future<BatchReviewReceipt> settle(
    String batch,
    String job,
    String snapshotId,
  ) async => BatchReviewReceipt.fromJson(
    unwrapObject(
      await _client.post(
        '${_job(batch, job)}/confirmations/${Uri.encodeComponent(snapshotId)}/settle',
      ),
    ),
  );
}
