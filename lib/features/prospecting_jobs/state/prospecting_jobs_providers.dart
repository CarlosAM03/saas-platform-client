import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../platform_api/platform_api.dart';
import '../../auth/state/tenant_permissions.dart';
import '../data/prospecting_jobs_repository.dart';

final prospectingJobsRepositoryProvider =
    Provider.autoDispose<ProspectingJobsRepository>((ref) {
  if (ref.watch(sessionScopeProvider)?.tenantId == null) {
    throw StateError('Selecciona una organización');
  }
  return ApiProspectingJobsRepository(ref.watch(platformApiProvider));
});
typedef JobsPageKey = ({int page, SortOrder order});
final jobsListProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ProspectingJobSummary>, JobsPageKey>((ref, key) {
  ref.watch(sessionScopeProvider);
  return ref.watch(prospectingJobsRepositoryProvider).list(PaginationQuery(
      page: key.page,
      limit: 20,
      sortBy: SortField.createdAt,
      sortOrder: key.order));
});
bool isJobActive(ProspectingJobStatus status) =>
    status == ProspectingJobStatus.QUEUED ||
    status == ProspectingJobStatus.RUNNING;

/// One request at a time. Disposal/session replacement interrupts the polling delay.
final jobMonitorProvider = StreamProvider.autoDispose
    .family<ProspectingJobDetail, String>((ref, id) async* {
  ref.watch(sessionScopeProvider);
  final repository = ref.watch(prospectingJobsRepositoryProvider);
  final disposed = Completer<void>();
  Timer? timer;
  var active = true;
  void stop() {
    active = false;
    timer?.cancel();
    if (!disposed.isCompleted) disposed.complete();
  }
  ref.onCancel(stop);
  ref.onDispose(stop);
  ref.onResume(ref.invalidateSelf);
  while (active) {
    final job = await repository.get(id);
    if (!active) return;
    yield job;
    if (!isJobActive(job.status)) return;
    final next = Completer<void>();
    timer = Timer(const Duration(seconds: 4), next.complete);
    await Future.any([next.future, disposed.future]);
  }
});
