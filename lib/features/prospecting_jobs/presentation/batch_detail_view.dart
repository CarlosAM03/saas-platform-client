import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/services/file_service.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../state/batch_providers.dart';
import 'batch_labels.dart';
import 'batch_review_panel.dart';

/// Batch v1 detail: status recovery, review, confirmation and export.
/// Used by the generation page and by `/jobs/:id` when Batch is enabled.
class BatchDetailView extends ConsumerStatefulWidget {
  const BatchDetailView({
    required this.batch,
    this.onUpdated,
    this.onMutated,
    super.key,
  });

  final BatchSummary batch;

  /// Receives the re-read batch after reconciliation.
  final ValueChanged<BatchSummary>? onUpdated;

  /// Called after a confirmation changes campaigns/prospects.
  final VoidCallback? onMutated;

  @override
  ConsumerState<BatchDetailView> createState() => _BatchDetailViewState();
}

class _BatchDetailViewState extends ConsumerState<BatchDetailView> {
  late BatchSummary _batch = widget.batch;
  BatchReview? review;
  BatchJobSummary? reviewJob;
  BatchReviewReceipt? receipt;
  bool busy = false;
  String? error;

  @override
  void didUpdateWidget(covariant BatchDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batch.id != widget.batch.id) {
      _batch = widget.batch;
      review = null;
      reviewJob = null;
      receipt = null;
      error = null;
    } else if (oldWidget.batch != widget.batch) {
      _batch = widget.batch;
    }
  }

  Future<void> run<T>(
    Future<T> Function(ProspectingBatchesApi) action,
    void Function(T) apply, {
    bool mutation = false,
  }) async {
    final scope = ref.read(sessionScopeProvider);
    if (busy || scope == null) return;
    bool sameSession() => mounted && ref.read(sessionScopeProvider) == scope;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await action(ref.read(batchApiProvider));
      if (!sameSession()) return;
      setState(() => apply(value));
      if (!sameSession()) return;
      widget.onUpdated?.call(_batch);
      if (mutation) widget.onMutated?.call();
    } catch (problem) {
      if (!sameSession()) return;
      setState(() => error = const ErrorMapper().userMessage(problem));
    } finally {
      if (sameSession()) setState(() => busy = false);
    }
  }

  Future<void> download(BatchJobSummary job, BatchExportFormat format) =>
      run((api) async {
        final scope = ref.read(sessionScopeProvider);
        final bytes = await api.export(_batch.id, job.id, format);
        if (!mounted || scope != ref.read(sessionScopeProvider)) return false;
        return ref
            .read(fileServiceProvider)
            .save('prospectos-${job.id}.${format.name}', bytes.bytes);
      }, (_) {});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        batchAdmissionLabel(_batch.admission),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(
        ref
                .watch(campaignsDetailProvider(_batch.campaignId))
                .asData
                ?.value
                .name ??
            'Campaña ${_batch.campaignId}',
      ),
      if (_batch.remoteObserved == false)
        const Text('Service aún no confirma la existencia del lote.'),
      Wrap(
        children: [
          TextButton(
            onPressed: busy
                ? null
                : () => run((api) => api.reconcile(_batch.id), (BatchSummary value) {
                    _batch = value;
                    receipt = null;
                  }),
            child: const Text('Consultar estado'),
          ),
        ],
      ),
      if (error != null)
        Semantics(liveRegion: true, child: Text(error!)),
      if (busy) const LinearProgressIndicator(),
      for (final job in _batch.jobs) _jobCard(job),
      if (review case final value?)
        BatchReviewPanel(
          key: ValueKey(value.snapshotId),
          review: value,
          busy: busy,
          confirm: (decisions) => run(
            (api) => api.confirm(
              _batch.id,
              reviewJob!.id,
              value.snapshotId,
              decisions,
            ),
            (confirmation) {
              receipt = confirmation;
              review = null;
            },
            mutation: true,
          ),
        ),
    ],
  );

  Widget _jobCard(BatchJobSummary job) {
    final currentReceipt = (reviewJob?.id == job.id ? receipt : null) ??
        job.confirmation;
    return Card(
      child: ListTile(
        title: Text('Consulta ${job.position + 1} · ${batchJobLabel(job.state)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.availability case final availability?)
              Text(batchAvailabilityLabel(availability)),
            if (job.progress case final progress?)
              Text(
                progress['stage'] is String
                    ? 'Etapa observada · ${progress['stage']}'
                    : '${progress['name']} · ${progress['value']}',
              ),
            if (currentReceipt case final confirmed?)
              _receipt(confirmed, job.id),
            if (job.availability == BatchAvailability.AVAILABLE &&
                currentReceipt == null)
              Wrap(
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => run(
                            (api) => api.preview(_batch.id, job.id),
                            (value) {
                              reviewJob = job;
                              review = value;
                              receipt = null;
                            },
                          ),
                    child: const Text('Revisar resultados'),
                  ),
                  for (final format in BatchExportFormat.values)
                    TextButton(
                      onPressed: busy ? null : () => download(job, format),
                      child: Text('Exportar ${format.name.toUpperCase()}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _receipt(BatchReviewReceipt confirmed, String job) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${confirmed.processedCount} incorporados · ${confirmed.omittedCount} omitidos',
      ),
      Text(confirmed.ackAt == null ? 'ACK pendiente' : 'ACK confirmado'),
      Text(confirmed.purgedAt == null ? 'Purga pendiente' : 'Purga confirmada'),
      if (confirmed.purgedAt == null)
        TextButton(
          onPressed: busy
              ? null
              : () => run(
                  (api) => api.settle(_batch.id, job, confirmed.snapshotId),
                  (value) {
                    receipt = value;
                    for (final item in _batch.jobs) {
                      if (item.id == job) reviewJob = item;
                    }
                  },
                  mutation: true,
                ),
          child: const Text('Reconciliar ACK y purga'),
        ),
    ],
  );
}
