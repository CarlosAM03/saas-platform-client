<<<<<<< HEAD
import 'dart:async';
=======
import '../../../shared/widgets/session_dialog.dart';
>>>>>>> fix/f5-foundation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../../prospects/state/prospects_providers.dart';
import '../state/prospecting_jobs_providers.dart';
import '../state/prospecting_capabilities.dart';

const jobStatusLabels = {
  ProspectingJobStatus.QUEUED: 'En cola',
  ProspectingJobStatus.RUNNING: 'En ejecución',
  ProspectingJobStatus.COMPLETED: 'Completado',
  ProspectingJobStatus.FAILED: 'Fallido',
  ProspectingJobStatus.CANCELLED: 'Cancelado',
};

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});
  @override
  ConsumerState<JobsPage> createState() => _JobsState();
}

class _JobsState extends ConsumerState<JobsPage> {
  JobsPageKey query = (page: 1, order: SortOrder.desc);
  @override
  Widget build(BuildContext context) {
    final value = ref.watch(jobsListProvider(query));
    return FeaturePage(
      title: 'Trabajos de prospección',
      actions: [
        FilledButton(
          onPressed: () => context.go('/generate'),
          child: const Text('Nueva búsqueda'),
        ),
        IconButton(
          tooltip: 'Actualizar trabajos',
          onPressed: () => ref.invalidate(jobsListProvider),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Cambiar orden de trabajos',
          onPressed: () => setState(
            () => query = (
              page: 1,
              order: query.order == SortOrder.desc
                  ? SortOrder.asc
                  : SortOrder.desc,
            ),
          ),
          icon: const Icon(Icons.sort),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: AsyncPanel(
              value: value,
              retry: () => ref.invalidate(jobsListProvider),
              data: (page) => page.items.isEmpty
                  ? const Center(
                      child: Text('Aún no hay trabajos de prospección.'),
                    )
                  : ListView(
                      children: [
                        for (final job in page.items)
                          Card(
                            child: ListTile(
                              title: Text('Trabajo ${job.id}'),
                              subtitle: Text(
                                'Creado: ${job.createdAt.toLocal()}',
                              ),
                              trailing: Text(jobStatusLabels[job.status]!),
                              onTap: () => context.go('/jobs/${job.id}'),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          if (value.asData case final data?)
            Row(
              children: [
                IconButton(
                  tooltip: 'Trabajos anteriores',
                  onPressed: query.page > 1
                      ? () => setState(
                          () => query = (
                            page: query.page - 1,
                            order: query.order,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    'Página ${query.page} · ${data.value.meta.total} trabajos',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'Trabajos siguientes',
                  onPressed: query.page < data.value.meta.totalPages
                      ? () => setState(
                          () => query = (
                            page: query.page + 1,
                            order: query.order,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage(this.id, {super.key});
  final String id;
  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailState();
}

class _JobDetailState extends ConsumerState<JobDetailPage> {
  bool busy = false, hidden = false;
  Timer? expiryTimer;
  DateTime? scheduledExpiry;
  @override
  void dispose() {
    expiryTimer?.cancel();
    super.dispose();
  }

  void watchExpiry(ProspectingJobDetail job) {
    final expiry = job.resultsExpiresAt;
    if (expiry == scheduledExpiry) return;
    expiryTimer?.cancel();
    scheduledExpiry = expiry;
    if (expiry == null || !expiry.isAfter(DateTime.now())) return;
    expiryTimer = Timer(
      expiry.difference(DateTime.now()) + const Duration(milliseconds: 1),
      () {
        if (!mounted) return;
        setState(() {});
        ref.invalidate(jobMonitorProvider(widget.id));
      },
    );
  }

  String? notice;
  Object? error;
  Future<void> action(Future<void> Function() task) async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
      error = null;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String text) async =>
      await showSessionDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => FeaturePage(
    title: 'Detalle del trabajo',
    actions: [
      TextButton(
        onPressed: () => context.go('/jobs'),
        child: const Text('Ver trabajos'),
      ),
      IconButton(
        tooltip: 'Actualizar trabajo',
        onPressed: busy
            ? null
            : () => ref.invalidate(jobMonitorProvider(widget.id)),
        icon: const Icon(Icons.refresh),
      ),
    ],
    child: AsyncPanel(
      value: ref.watch(jobMonitorProvider(widget.id)),
      retry: () => ref.invalidate(jobMonitorProvider(widget.id)),
      data: (job) {
        watchExpiry(job);
        final expired =
            job.resultsExpiresAt != null &&
            !job.resultsExpiresAt!.isAfter(DateTime.now());
        final results = hidden || expired || !job.resultsAvailable
            ? null
            : job.results;
        return ListView(
          children: [
            Text(
              jobStatusLabels[job.status]!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${job.query.keyword} · ${job.query.location} · hasta ${job.query.limit} resultados',
            ),
            Text('Creado: ${job.createdAt.toLocal()}'),
            TextButton(
              onPressed: () => context.go('/campaigns/${job.campaignId}'),
              child: const Text('Ver campaña'),
            ),
            if (isJobActive(job.status)) ...[
              const LinearProgressIndicator(),
              const Text('Actualizando el estado cada 4 segundos…'),
            ],
            if (job.dispatchState == ProspectingDispatchState.UNCERTAIN ||
                job.dispatchState == ProspectingDispatchState.PENDING)
              const Text(
                'La aceptación o finalización no está confirmada. La búsqueda puede continuar; no se repetirá automáticamente.',
              ),
            if (job.error != null) Text(job.error!),
            if (job.resultsExpiresAt != null)
              Text(
                'Resultados disponibles hasta: ${job.resultsExpiresAt!.toLocal()}',
              ),
            if (job.status == ProspectingJobStatus.FAILED)
              job.retryAllowed
                  ? OutlinedButton(
                      onPressed: () => context.go(
                        '/generate?retryJobId=${Uri.encodeComponent(job.id)}',
                      ),
                      child: const Text('Repetir búsqueda manualmente'),
                    )
                  : const Text(
                      'No se confirmó que la ejecución haya terminado. Espera la confirmación antes de repetirla.',
                    ),
            if (notice != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(notice!)),
            if (error != null)
              Text(
                const ErrorMapper().userMessage(error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Text(pendingProspectorMessage),
            if (busy) const LinearProgressIndicator(),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (isJobActive(job.status))
                  OutlinedButton(
                    onPressed:
                        busy ||
                            !ref.watch(prospectingCapabilitiesProvider).cancel
                        ? null
                        : () => action(() async {
                            final scope = ref.read(sessionScopeProvider);
                            if (!await confirm(
                              'Cancelar trabajo',
                              'Se solicitará detener la búsqueda. El trabajo terminará cuando el motor confirme la cancelación.',
                            )) {
                              return;
                            }
                            if (!mounted ||
                                scope != ref.read(sessionScopeProvider)) {
                              return;
                            }
                            await ref
                                .read(prospectingJobsRepositoryProvider)
                                .cancel(job.id);
                            if (!mounted ||
                                scope != ref.read(sessionScopeProvider)) {
                              return;
                            }
                            setState(() => notice = 'Cancelación solicitada.');
                            ref.invalidate(jobMonitorProvider(job.id));
                            ref.invalidate(jobsListProvider);
                          }),
                    child: const Text('Cancelar trabajo'),
                  ),
                if (job.resultsAvailable &&
                    !expired &&
                    !hidden &&
                    job.status == ProspectingJobStatus.COMPLETED) ...[
                  FilledButton(
                    onPressed:
                        busy ||
                            !ref.watch(prospectingCapabilitiesProvider).persist
                        ? null
                        : () => action(() async {
                            final scope = ref.read(sessionScopeProvider);
                            final result = await ref
                                .read(prospectingJobsRepositoryProvider)
                                .persist(job.id);
                            if (!mounted ||
                                scope != ref.read(sessionScopeProvider)) {
                              return;
                            }
                            setState(() {
                              hidden = true;
                              notice =
                                  '${result.persisted} guardados · ${result.skipped} omitidos';
                            });
                            ref.invalidate(jobMonitorProvider(job.id));
                            ref.invalidate(prospectsListProvider);
                            ref.invalidate(campaignProspectsProvider);
                            ref.invalidate(dashboardProvider);
                          }),
                    child: const Text('Guardar en campaña'),
                  ),
                  for (final format in ExportFormat.values)
                    OutlinedButton(
                      onPressed:
                          busy ||
                              !ref.watch(prospectingCapabilitiesProvider).export
                          ? null
                          : () => action(() async {
                              final scope = ref.read(sessionScopeProvider);
                              final file = await ref
                                  .read(prospectingJobsRepositoryProvider)
                                  .export(job.id, format);
                              if (!mounted ||
                                  scope != ref.read(sessionScopeProvider)) {
                                return;
                              }
                              final saved = await ref
                                  .read(fileServiceProvider)
                                  .save(
                                    'prospectos-${job.id}.${format.name}',
                                    file.bytes,
                                  );
                              if (mounted) {
                                setState(
                                  () => notice = saved
                                      ? 'Archivo guardado.'
                                      : 'Descarga cancelada.',
                                );
                              }
                            }),
                      child: Text('Exportar ${format.name.toUpperCase()}'),
                    ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => action(() async {
                            if (await confirm(
                              'Descartar vista de resultados',
                              'Se cerrará esta vista. Los resultados seguirán sujetos al plazo de disponibilidad del Backend.',
                            )) {
                              if (mounted) {
                                ref.invalidate(jobMonitorProvider(job.id));
                                this.context.go('/jobs');
                              }
                            }
                          }),
                    child: const Text('Descartar vista'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (results != null) ...[
              Text(
                '${results.length} resultados temporales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (results.isEmpty)
                const Text('La búsqueda no encontró negocios.'),
              for (final result in results)
                Card(
                  child: ListTile(
                    title: Text(result.name),
                    subtitle: Text(
                      [
                        result.category,
                        result.address,
                        result.phone,
                        result.email,
                        result.website,
                      ].whereType<String>().join('\n'),
                    ),
                  ),
                ),
            ] else if (job.status == ProspectingJobStatus.COMPLETED && !hidden)
              const Text(
                'Los resultados temporales no están disponibles o vencieron. El historial del trabajo se conserva.',
              ),
          ],
        );
      },
    ),
  );
}
