import 'dart:async';
import '../../../platform_api/platform_api.dart';
import '../../prospecting_jobs/state/batch_providers.dart'
    show prospectingBatchEnabled;

class DashboardData {
  const DashboardData({
    required this.campaigns,
    required this.prospects,
    this.jobs,
    this.jobsError,
    this.batches,
    this.batchesError,
  });
  final PaginatedResult<Campaign> campaigns;
  final PaginatedResult<Prospect> prospects;
  final PaginatedResult<ProspectingJobSummary>? jobs;
  final Object? jobsError;
  final PaginatedResult<BatchSummary>? batches;
  final Object? batchesError;
}

abstract interface class DashboardRepository {
  Future<DashboardData> load({bool includeProspecting = true});
}

class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository(this.api);
  final PlatformApi api;
  @override
  Future<DashboardData> load({bool includeProspecting = true}) async {
    const recent = PaginationQuery(
      page: 1,
      limit: 5,
      sortBy: SortField.createdAt,
      sortOrder: SortOrder.desc,
    );
    Object? prospectingError;
    final values = await Future.wait<Object?>([
      api.campaigns.list(query: recent),
      api.prospects.list(query: recent),
      if (!includeProspecting)
        Future<Object?>.value(null)
      else if (prospectingBatchEnabled)
        api.batches
            .list(1)
            .then<Object?>(
              (value) => value,
              onError: (Object error) {
                prospectingError = error;
                return null;
              },
            )
      else
        api.prospectingJobs
            .list(query: recent)
            .then<Object?>(
              (value) => value,
              onError: (Object error) {
                prospectingError = error;
                return null;
              },
            ),
    ]);
    return DashboardData(
      campaigns: values[0] as PaginatedResult<Campaign>,
      prospects: values[1] as PaginatedResult<Prospect>,
      jobs: prospectingBatchEnabled
          ? null
          : values[2] as PaginatedResult<ProspectingJobSummary>?,
      jobsError: prospectingBatchEnabled ? null : prospectingError,
      batches: prospectingBatchEnabled
          ? values[2] as PaginatedResult<BatchSummary>?
          : null,
      batchesError: prospectingBatchEnabled ? prospectingError : null,
    );
  }
}
