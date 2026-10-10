import '../../shared/models/api_models.dart';
import '../pagination_query.dart';

String entityPath(String resource, String id) {
  if (id.isEmpty) throw ArgumentError.value(id, 'id');
  return '/api/v1/$resource/${Uri.encodeComponent(id)}';
}

void parseEmpty(Object? response) {
  if (unwrapObject(response).isNotEmpty) {
    throw const FormatException('Expected empty success data');
  }
}

const commonSorts = {
  SortField.name,
  SortField.email,
  SortField.status,
  SortField.createdAt,
  SortField.updatedAt
};
const campaignSorts = {
  SortField.name,
  SortField.status,
  SortField.createdAt,
  SortField.updatedAt
};
const jobSorts = {
  SortField.id,
  SortField.status,
  SortField.createdAt,
  SortField.updatedAt,
  SortField.startedAt,
  SortField.completedAt
};
