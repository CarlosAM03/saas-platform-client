import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/api_exception.dart';
import '../../../platform_api/campaign_participation_api.dart';
import '../../../platform_api/platform_api.dart' show PaginationMeta;
import '../../../shared/widgets/feature_widgets.dart';
import '../../../shared/widgets/session_dialog.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/participation_providers.dart';
import '../../prospects/presentation/prospects_page.dart';
import 'commercial_stage_labels.dart';

String _activityValue(CampaignActivity activity, String? value) {
  if (value == null) return '';
  return activity.type == CampaignActivityType.STAGE_CHANGE
      ? commercialStageLabelForCode(value)
      : value;
}

class ParticipationError extends StatelessWidget {
  const ParticipationError(this.error, {this.retry, super.key});
  final Object error;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => error is ApiException
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (error as ApiException).kind == ApiErrorKind.notFound
                  ? 'No encontrado o fuera de tu organización'
                  : '${(error as ApiException).code ?? ''}: ${(error as ApiException).message}',
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Reintentar')),
          ],
        )
      : ErrorView(error, retry: retry);
}

class ParticipationAsync<T> extends StatelessWidget {
  const ParticipationAsync({
    required this.value,
    required this.data,
    required this.retry,
    super.key,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnReload: false,
    skipLoadingOnRefresh: false,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => ParticipationError(e, retry: retry),
    data: data,
  );
}

class ParticipationPagination extends StatelessWidget {
  const ParticipationPagination({
    required this.meta,
    required this.change,
    super.key,
  });
  final PaginationMeta meta;
  final ValueChanged<int> change;
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        tooltip: 'Página anterior',
        onPressed: meta.page > 1 ? () => change(meta.page - 1) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Text('Página ${meta.page} · ${meta.total} registros'),
      IconButton(
        tooltip: 'Página siguiente',
        onPressed: meta.page < meta.totalPages
            ? () => change(meta.page + 1)
            : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

class ParticipationPanel extends ConsumerStatefulWidget {
  const ParticipationPanel(this.participation, {super.key});
  final ParticipationKey participation;
  @override
  ConsumerState<ParticipationPanel> createState() => _ParticipationPanelState();
}

class _ParticipationPanelState extends ConsumerState<ParticipationPanel> {
  int page = 1;
  bool busy = false;
  Object? error;
  ParticipationKey get key => widget.participation;
  void refresh() {
    ref.invalidate(participationProvider(key));
    ref.invalidate(participationActivitiesProvider);
    ref.invalidate(filteredCampaignProspectsProvider);
    ref.invalidate(campaignDashboardProvider(key.campaign));
    ref.invalidate(responsibleOptionsProvider(key));
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    final scope = ref.read(sessionScopeProvider);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await task();
      if (mounted && scope == ref.read(sessionScopeProvider)) refresh();
    } catch (e) {
      if (mounted && scope == ref.read(sessionScopeProvider)) {
        setState(() => error = e);
      }
    } finally {
      if (mounted && scope == ref.read(sessionScopeProvider)) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> activity({String? correctsId}) => showSessionDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(
        correctsId == null ? 'Registrar actividad' : 'Corregir declaración',
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: EntityEditor(
          errorBuilder: (error) => ParticipationError(error),
          fields: [
            EditorField(
              'type',
              'Tipo de declaración',
              initial: 'NOTE',
              options: manualActivityTypes.map((e) => e.name).toList(),
            ),
            const EditorField('content', 'Contenido', required: true),
            const EditorField(
              'declaredAt',
              'Fecha declarada (ISO con zona, opcional)',
            ),
          ],
          save: (values) async {
            final scope = ref.read(sessionScopeProvider);
            await ref
                .read(participationRepositoryProvider)
                .record(
                  key.campaign,
                  key.prospect,
                  type: CampaignActivityType.values.byName(values['type']!),
                  content: values['content']!,
                  declaredAt: values['declaredAt']!.isEmpty
                      ? null
                      : values['declaredAt'],
                  correctsId: correctsId,
                );
            if (!mounted || scope != ref.read(sessionScopeProvider)) return;
            refresh();
            if (dialog.mounted) Navigator.pop(dialog);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
  Future<void> evaluation(CampaignParticipation p) => showSessionDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Evaluación comercial'),
      content: SizedBox(
        width: 520,
        height: 330,
        child: EntityEditor(
          errorBuilder: (error) => ParticipationError(error),
          fields: [
            EditorField(
              'evaluation',
              'Evaluación',
              initial: p.evaluation.name,
              options: CommercialEvaluation.values.map((e) => e.name).toList(),
            ),
            EditorField(
              'reason',
              'Motivo (obligatorio para NO_APTO)',
              initial: p.evaluationReason ?? '',
            ),
          ],
          save: (values) async {
            final scope = ref.read(sessionScopeProvider);
            // The server owns validation and returns the contractual 400 when a reason is missing.
            await ref
                .read(participationRepositoryProvider)
                .evaluate(
                  key.campaign,
                  key.prospect,
                  CommercialEvaluation.values.byName(values['evaluation']!),
                  values['reason']!.isEmpty ? null : values['reason'],
                );
            if (!mounted || scope != ref.read(sessionScopeProvider)) return;
            refresh();
            if (dialog.mounted) Navigator.pop(dialog);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ParticipationAsync(
    value: ref.watch(participationProvider(key)),
    retry: refresh,
    data: (p) => ListView(
      children: [
        Text('Etapa comercial: ${p.stage.label}'),
        DropdownButton<CommercialStage>(
          value: p.stage,
          items: CommercialStage.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: busy
              ? null
              : (s) {
                  if (s != null) {
                    run(() async {
                      await ref
                          .read(participationRepositoryProvider)
                          .stage(key.campaign, key.prospect, s);
                    });
                  }
                },
        ),
        Text('Evaluación: ${p.evaluation.name}'),
        if (p.evaluationReason != null) Text('Motivo: ${p.evaluationReason}'),
        TextButton(
          onPressed: busy ? null : () => evaluation(p),
          child: const Text('Cambiar evaluación'),
        ),
        Text('Responsable: ${p.responsible?.name ?? 'Sin asignar'}'),
        if (p.responsible?.eligible == false)
          const Text('Responsable no elegible: pendiente de reasignación'),
        ParticipationAsync(
          value: ref.watch(responsibleOptionsProvider(key)),
          retry: () => ref.invalidate(responsibleOptionsProvider(key)),
          data: (users) => DropdownButton<String>(
            hint: const Text('Asignar responsable'),
            value: null,
            items: [
              const DropdownMenuItem(value: '', child: Text('Sin asignar')),
              for (final u in users)
                DropdownMenuItem(value: u.id, child: Text(u.name)),
            ],
            onChanged: busy
                ? null
                : (id) {
                    if (id != null) {
                      run(() async {
                        await ref
                            .read(participationRepositoryProvider)
                            .assign(
                              key.campaign,
                              key.prospect,
                              id.isEmpty ? null : id,
                            );
                      });
                    }
                  },
          ),
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) ParticipationError(error!),
        TextButton(
          onPressed: busy ? null : () => activity(),
          child: const Text('Registrar actividad'),
        ),
        TextButton(
          onPressed: busy
              ? null
              : () => showSessionDialog<void>(
                  context: context,
                  builder: (dialog) => AlertDialog(
                    title: const Text('Editar maestro compartido'),
                    content: SizedBox(
                      width: 650,
                      height: 600,
                      child: ProspectFormPage(
                        id: key.prospect,
                        contextCampaignId: key.campaign,
                        onSaved: () {
                          refresh();
                          Navigator.pop(dialog);
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
          child: const Text('Editar maestro compartido'),
        ),
        const Text('Bitácora contextual'),
        ParticipationAsync(
          value: ref.watch(
            participationActivitiesProvider((participation: key, page: page)),
          ),
          retry: refresh,
          data: (activities) => Column(
            children: [
              if (activities.items.isEmpty)
                const Text('No hay actividades registradas.'),
              for (final a in activities.items)
                ListTile(
                  title: Text(
                    '${a.isManual ? 'Declaración humana' : 'Evento automático'} · ${a.type.name}',
                  ),
                  subtitle: Text(
                    '${a.content ?? '${_activityValue(a, a.previousValue)} → ${_activityValue(a, a.newValue)}'}\nAutor: ${a.actorName ?? 'Sistema'}\nRegistro: ${a.recordedAt.toLocal()}${a.declaredAt == null ? '' : '\nDeclarada: ${a.declaredAt!.toLocal()}'}${a.correctsId == null ? '' : '\nCorrige: ${a.correctsId}'}${a.reason == null ? '' : '\nMotivo: ${a.reason}'}',
                  ),
                  trailing: a.isManual
                      ? TextButton(
                          onPressed: busy
                              ? null
                              : () => activity(correctsId: a.id),
                          child: const Text('Corregir'),
                        )
                      : null,
                ),
              ParticipationPagination(
                meta: activities.meta,
                change: (value) => setState(() => page = value),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
