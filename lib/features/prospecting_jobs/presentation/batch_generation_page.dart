import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/widgets/campaign_picker.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';

final _batchApi = Provider.autoDispose<ProspectingBatchesApi>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(platformApiProvider).batches;
});

final _history = FutureProvider.autoDispose.family((ref, int page) {
  final scope = ref.watch(sessionScopeProvider);
  if (scope?.tenantId == null) {
    throw StateError('Se requiere una organización activa');
  }
  return ref.watch(_batchApi).list(page);
});

class BatchGenerationPage extends ConsumerStatefulWidget {
  const BatchGenerationPage({super.key});

  @override
  ConsumerState<BatchGenerationPage> createState() => _BatchGenerationState();
}

class _QueryFields {
  final keyword = TextEditingController();
  final location = TextEditingController();
  final limit = TextEditingController(text: '20');

  BatchQuery read() => BatchQuery(
    keyword.text.trim(),
    location.text.trim(),
    int.parse(limit.text),
  );

  void dispose() {
    keyword.dispose();
    location.dispose();
    limit.dispose();
  }
}

class _BatchGenerationState extends ConsumerState<BatchGenerationPage> {
  final form = GlobalKey<FormState>();
  final fields = [_QueryFields()];
  Campaign? campaign;
  BatchSummary? selected;
  BatchReview? review;
  BatchJobSummary? reviewJob;
  BatchReviewReceipt? receipt;
  String? error;
  String? requestKey;
  String? signature;
  bool busy = false;
  bool uncertain = false;
  int page = 1;

  @override
  void dispose() {
    for (final query in fields) {
      query.dispose();
    }
    super.dispose();
  }

  Future<void> run<T>(
    Future<T> Function(ProspectingBatchesApi) action,
    void Function(T) apply, {
    bool admission = false,
  }) async {
    final scope = ref.read(sessionScopeProvider);
    if (busy || scope == null) return;
    bool sameSession() => mounted && ref.read(sessionScopeProvider) == scope;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await action(ref.read(_batchApi));
      if (sameSession()) setState(() => apply(value));
    } catch (problem) {
      if (!sameSession()) return;
      setState(() {
        if (admission) {
          uncertain =
              problem is! ApiException ||
              problem.kind == ApiErrorKind.network ||
              problem.kind == ApiErrorKind.unknown;
        }
        error = uncertain
            ? 'La respuesta no se pudo confirmar. Consulta el historial o vuelve a enviar los mismos datos para recuperar la solicitud existente.'
            : const ErrorMapper().userMessage(problem);
      });
    } finally {
      if (sameSession()) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (campaign == null) {
      setState(() => error = 'Selecciona una campaña.');
      return;
    }
    if (form.currentState?.validate() != true) return;
    final queries = fields.map((query) => query.read()).toList();
    final campaignId = campaign!.id;
    final current = jsonEncode([
      campaignId,
      ...queries.map((query) => query.toJson()),
    ]);
    if (signature != current) {
      signature = current;
      final secure = Random.secure();
      requestKey = List.generate(
        24,
        (_) => secure.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    }
    await run((api) => api.create(campaignId, queries, requestKey!), (batch) {
      uncertain = false;
      select(batch);
      ref.invalidate(_history(page));
    }, admission: true);
  }

  void select(BatchSummary batch) {
    selected = batch;
    review = null;
    reviewJob = null;
    receipt = null;
  }

  Future<void> download(
    BatchSummary batch,
    BatchJobSummary job,
    BatchExportFormat format,
  ) {
    return run((api) async {
      final scope = ref.read(sessionScopeProvider);
      final bytes = await api.export(batch.id, job.id, format);
      if (!mounted || scope != ref.read(sessionScopeProvider)) return false;
      return ref
          .read(fileServiceProvider)
          .save('prospectos.${format.name}', bytes.bytes);
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    if (permissions.asData?.value.canCreateProspects != true) {
      return FeaturePage(
        title: 'Prospección por lotes',
        child: PermissionGate(
          permissions: permissions,
          allowed: false,
          child: const SizedBox.shrink(),
        ),
      );
    }
    return FeaturePage(
      title: 'Prospección por lotes',
      child: PermissionGate(
        permissions: permissions,
        allowed: permissions.asData?.value.canCreateProspects == true,
        child: ListView(
          children: [
            if (error != null) Semantics(liveRegion: true, child: Text(error!)),
            if (busy) const LinearProgressIndicator(),
            if (selected case final batch?) _detail(batch) else _form(),
            const Divider(),
            Text('Mis lotes', style: Theme.of(context).textTheme.titleMedium),
            ref
                .watch(_history(page))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (problem, _) => TextButton(
                    onPressed: () => ref.invalidate(_history(page)),
                    child: Text(
                      'Reintentar · ${const ErrorMapper().userMessage(problem)}',
                    ),
                  ),
                  data: (history) => Column(
                    children: [
                      if (history.items.isEmpty)
                        const Text('No hay lotes registrados.'),
                      for (final batch in history.items)
                        ListTile(
                          title: Text(batch.createdAt.toLocal().toString()),
                          subtitle: Text(_admissionLabel(batch.admission)),
                          onTap: busy
                              ? null
                              : () => setState(() => select(batch)),
                        ),
                      if (page > 1 || page < history.meta.totalPages)
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: page > 1
                                  ? () => setState(() => page--)
                                  : null,
                              child: const Text('Anterior'),
                            ),
                            TextButton(
                              onPressed: page < history.meta.totalPages
                                  ? () => setState(() => page++)
                                  : null,
                              child: const Text('Siguiente'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final editable = !busy && !uncertain;
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: editable
                ? () async {
                    final scope = ref.read(sessionScopeProvider);
                    final chosen = await pickCampaign(context, ref);
                    if (mounted &&
                        chosen != null &&
                        scope == ref.read(sessionScopeProvider)) {
                      setState(() => campaign = chosen);
                    }
                  }
                : null,
            child: Text(campaign?.name ?? 'Seleccionar campaña'),
          ),
          for (final (index, query) in fields.indexed)
            Padding(
              key: ObjectKey(query),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Consulta ${index + 1}'),
                  _field(query.keyword, 'Tipo de negocio', editable),
                  _field(query.location, 'Ubicación', editable),
                  TextFormField(
                    controller: query.limit,
                    enabled: editable,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Máximo de resultados (1–150)',
                    ),
                    validator: (input) {
                      final limit = int.tryParse(input ?? '');
                      return limit == null || limit < 1 || limit > 150
                          ? 'Elige de 1 a 150.'
                          : null;
                    },
                  ),
                  if (fields.length > 1)
                    TextButton(
                      onPressed: editable
                          ? () {
                              setState(() => fields.remove(query));
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => query.dispose(),
                              );
                            }
                          : null,
                      child: Text('Quitar consulta ${index + 1}'),
                    ),
                ],
              ),
            ),
          if (fields.length < 5)
            TextButton(
              onPressed: editable
                  ? () => setState(() => fields.add(_QueryFields()))
                  : null,
              child: const Text('Añadir consulta'),
            ),
          FilledButton(
            onPressed: busy ? null : submit,
            child: Text(
              uncertain ? 'Recuperar la misma solicitud' : 'Solicitar lote',
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    bool editable,
  ) => TextFormField(
    controller: controller,
    enabled: editable,
    decoration: InputDecoration(labelText: label),
    validator: (input) =>
        input == null || input.trim().isEmpty ? 'Campo obligatorio.' : null,
  );

  Widget _detail(BatchSummary batch) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _admissionLabel(batch.admission),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(
        ref
                .watch(campaignsDetailProvider(batch.campaignId))
                .asData
                ?.value
                .name ??
            'Campaña ${batch.campaignId}',
      ),
      if (batch.remoteObserved == false)
        const Text('Service aún no confirma la existencia del lote.'),
      Wrap(
        children: [
          TextButton(
            onPressed: busy
                ? null
                : () => run((api) => api.reconcile(batch.id), select),
            child: const Text('Consultar estado'),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    selected = null;
                    review = null;
                    receipt = null;
                    if (!uncertain) {
                      signature = null;
                      requestKey = null;
                      for (final query in fields) {
                        query.keyword.clear();
                        query.location.clear();
                      }
                    }
                  }),
            child: Text(
              uncertain ? 'Volver a la solicitud pendiente' : 'Nueva solicitud',
            ),
          ),
        ],
      ),
      for (final job in batch.jobs) _jobCard(batch, job),
      if (review case final value?)
        _ReviewPanel(
          key: ValueKey(value.snapshotId),
          review: value,
          busy: busy,
          confirm: (decisions) => run(
            (api) => api.confirm(
              batch.id,
              reviewJob!.id,
              value.snapshotId,
              decisions,
            ),
            (confirmation) {
              receipt = confirmation;
              review = null;
              ref.invalidate(_history(page));
            },
          ),
        ),
    ],
  );

  Widget _jobCard(BatchSummary batch, BatchJobSummary job) {
    final currentReceipt =
        (reviewJob?.id == job.id ? receipt : null) ?? job.confirmation;
    return Card(
      child: ListTile(
        title: Text('Consulta ${job.position + 1} · ${_jobLabel(job.state)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.availability case final availability?)
              Text(_availabilityLabel(availability)),
            if (job.progress case final progress?)
              Text(
                progress['stage'] is String
                    ? 'Etapa observada · ${progress['stage']}'
                    : '${progress['name']} · ${progress['value']}',
              ),
            if (currentReceipt case final confirmed?)
              _receipt(confirmed, batch.id, job.id),
            if (job.availability == BatchAvailability.AVAILABLE &&
                currentReceipt == null)
              Wrap(
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => run((api) => api.preview(batch.id, job.id), (
                            value,
                          ) {
                            reviewJob = job;
                            review = value;
                            receipt = null;
                          }),
                    child: const Text('Revisar resultados'),
                  ),
                  for (final format in BatchExportFormat.values)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => download(batch, job, format),
                      child: Text('Exportar ${format.name.toUpperCase()}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _receipt(
    BatchReviewReceipt confirmed,
    String batch,
    String job,
  ) => Column(
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
                  (api) => api.settle(batch, job, confirmed.snapshotId),
                  (value) {
                    receipt = value;
                    reviewJob = selected?.jobs.firstWhere(
                      (item) => item.id == job,
                    );
                    ref.invalidate(_history(page));
                  },
                ),
          child: const Text('Reconciliar ACK y purga'),
        ),
    ],
  );
}

class _ReviewPanel extends StatefulWidget {
  const _ReviewPanel({
    required this.review,
    required this.busy,
    required this.confirm,
    super.key,
  });
  final BatchReview review;
  final bool busy;
  final Future<void> Function(List<BatchRowDecision> choices) confirm;

  @override
  State<_ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<_ReviewPanel> {
  final decisions = <int, BatchRowDecision>{};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Revisión de resultados',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (widget.review.quality == BatchQuality.PARTIAL)
        const Text(
          'Resultado parcial. Solo se muestran registros disponibles.',
        ),
      if (widget.review.quality == BatchQuality.SUCCESS_WITH_ISSUES)
        const Text('El resultado se obtuvo con incidencias.'),
      Text('Vence el ${widget.review.expiresAt.toLocal()}'),
      for (final row in widget.review.rows)
        Card(
          child: ListTile(
            title: Text(row.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.address != null) Text(row.address!),
                if (row.phone != null) Text(row.phone!),
                if (row.website != null) Text(row.website!),
                if (row.blocked)
                  const Text('Identidad en conflicto. Solo se puede omitir.'),
                if (row.strongProspect != null)
                  const Text('Identidad fuerte verificada.'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: null,
                  decoration: const InputDecoration(
                    labelText: 'Acción de incorporación',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'SKIP',
                      child: Text('Omitir'),
                    ),
                    if (!row.blocked && row.strongProspect == null)
                      const DropdownMenuItem(
                        value: 'CREATE',
                        child: Text('Crear distinto'),
                      ),
                    if (!row.blocked)
                      for (final candidate
                          in row.strongProspect == null
                              ? row.candidates
                              : [row.strongProspect!]) ...[
                        DropdownMenuItem(
                          value: 'LINK_EXISTING|${candidate.id}',
                          child: Text('Vincular · ${candidate.name}'),
                        ),
                        DropdownMenuItem(
                          value: 'UPDATE_EXISTING|${candidate.id}',
                          child: Text('Actualizar maestro · ${candidate.name}'),
                        ),
                      ],
                  ],
                  onChanged: widget.busy
                      ? null
                      : (value) {
                          if (value == null) return;
                          final tokens = value.split('|');
                          setState(
                            () => decisions[row.index] = BatchRowDecision(
                              row.index,
                              BatchReviewAction.values.byName(tokens.first),
                              candidateId: tokens.length == 2
                                  ? tokens[1]
                                  : null,
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      FilledButton(
        onPressed: widget.busy || decisions.length != widget.review.rows.length
            ? null
            : () async {
                final shared = decisions.values.any(
                  (value) => value.action == BatchReviewAction.UPDATE_EXISTING,
                );
                final accepted = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar incorporación'),
                    content: Text(
                      shared
                          ? 'Los cambios del maestro se verán en las demás campañas vinculadas. ¿Confirmas las acciones seleccionadas?'
                          : '¿Confirmas incorporar los registros seleccionados a esta campaña?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Volver'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                );
                if (mounted && accepted == true) {
                  await widget.confirm(
                    decisions.values.toList(growable: false),
                  );
                }
              },
        child: const Text('Confirmar incorporación'),
      ),
    ],
  );
}

String _admissionLabel(BatchAdmission status) => switch (status) {
  BatchAdmission.PENDING => 'Solicitud registrada, admisión pendiente',
  BatchAdmission.UNCERTAIN => 'Admisión sin confirmar',
  BatchAdmission.ACCEPTED => 'Lote admitido',
  BatchAdmission.REJECTED => 'Lote rechazado',
};

String _jobLabel(BatchJobState? state) => switch (state) {
  null => 'Sin estado confirmado',
  BatchJobState.QUEUED => 'En cola',
  BatchJobState.RUNNING => 'En ejecución',
  BatchJobState.AWAITING_RESULTS => 'Esperando resultados',
  BatchJobState.COMPLETED => 'Completada',
  BatchJobState.FAILED => 'Fallida',
  BatchJobState.INTERRUPTED => 'Interrumpida',
  BatchJobState.SKIPPED => 'Omitida',
};

String _availabilityLabel(BatchAvailability status) => switch (status) {
  BatchAvailability.AVAILABLE => 'Resultados disponibles',
  BatchAvailability.EXPIRED => 'Resultados vencidos',
  BatchAvailability.PURGED => 'Resultados purgados',
  BatchAvailability.UNAVAILABLE => 'Resultados no disponibles',
};
