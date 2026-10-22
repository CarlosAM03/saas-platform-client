import 'dart:async';
import '../../../platform_api/platform_api.dart';

class DashboardData {
  const DashboardData(
      {required this.campaigns, required this.prospects, required this.jobs});
  final PaginatedResult<Campaign> campaigns;
  final PaginatedResult<Prospect> prospects;
  final PaginatedResult<ProspectingJobSummary> jobs;
}

abstract interface class DashboardRepository {
  Future<DashboardData> load();
}

class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository(this.api);
  final PlatformApi api;
  @override
  Future<DashboardData> load() async {
    const recent = PaginationQuery(
        page: 1,
        limit: 5,
        sortBy: SortField.createdAt,
        sortOrder: SortOrder.desc);
    final values = await Future.wait<Object>([
      api.campaigns.list(query: recent),
      api.prospects.list(query: recent),
      api.prospectingJobs.list(query: recent)
    ]);
    return DashboardData(
        campaigns: values[0] as PaginatedResult<Campaign>,
        prospects: values[1] as PaginatedResult<Prospect>,
        jobs: values[2] as PaginatedResult<ProspectingJobSummary>);
  }
}
