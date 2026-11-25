import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/campaign_participation_api.dart';
import '../../../platform_api/platform_api.dart'
    show PaginationQuery, SortField, SortOrder;
import '../../../shared/widgets/session_dialog.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/participation_providers.dart';
import 'commercial_stage_labels.dart';
import 'participation_panel.dart';

class CampaignProspectsPanel extends ConsumerWidget {
  const CampaignProspectsPanel(this.campaign, {super.key});
  final String campaign;
  @override
  Widget build(BuildContext context, WidgetRef ref) => _CampaignProspectsList(
    campaign,
    key: ValueKey((campaign, ref.watch(sessionScopeProvider))),
  );
}

class _CampaignProspectsList extends ConsumerStatefulWidget {
  const _CampaignProspectsList(this.campaign, {super.key});
  final String campaign;
  @override
  ConsumerState<_CampaignProspectsList> createState() =>
      _CampaignProspectsListState();
}

class _CampaignProspectsListState
    extends ConsumerState<_CampaignProspectsList> {
  final fields = {
    for (final key in [
      'search',
      'category',
      'address',
      'source',
      'responsibleId',
      'addedFrom',
      'addedTo',
      'activityFrom',
      'activityTo',
    ])
      key: TextEditingController(),
  };
  CommercialStage? stage;
  CommercialEvaluation? evaluation;
  int page = 1, limit = 20;
  SortField sort = SortField.name;
  SortOrder order = SortOrder.asc;
  CampaignProspectFilters filters = const CampaignProspectFilters();
  late PaginationQuery query = pagination();
  PaginationQuery pagination() =>
      PaginationQuery(page: page, limit: limit, sortBy: sort, sortOrder: order);
  void apply() => setState(() {
    page = 1;
    query = pagination();
    filters = CampaignProspectFilters(
      search: fields['search']!.text.trim(),
      category: fields['category']!.text.trim(),
      address: fields['address']!.text.trim(),
      source: fields['source']!.text.trim(),
      responsibleId: fields['responsibleId']!.text.trim(),
      stage: stage,
      evaluation: evaluation,
      addedFrom: fields['addedFrom']!.text.trim(),
      addedTo: fields['addedTo']!.text.trim(),
      activityFrom: fields['activityFrom']!.text.trim(),
      activityTo: fields['activityTo']!.text.trim(),
    );
  });
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (campaign: widget.campaign, query: query, filters: filters);
    final permissions = ref
        .watch(currentTenantPermissionsProvider)
        .asData
        ?.value;
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .4,
          ),
          child: SingleChildScrollView(
            child: ExpansionTile(
              title: Text(
                filters.toQuery().isEmpty
                    ? 'Filtrar prospectos'
                    : 'Filtros activos: ${filters.toQuery().length}',
              ),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final entry in const {
                      'search': 'Nombre o correo',
                      'category': 'Categoría',
                      'address': 'Dirección',
                      'source': 'Fuente exacta',
                      'responsibleId': 'Responsable (id o UNASSIGNED)',
                      'addedFrom': 'Incorporación desde (ISO con zona)',
                      'addedTo': 'Incorporación hasta (ISO con zona)',
                      'activityFrom': 'Actividad desde (ISO con zona)',
                      'activityTo': 'Actividad hasta (ISO con zona)',
                    }.entries)
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: fields[entry.key],
                          decoration: InputDecoration(labelText: entry.value),
                          onSubmitted: (_) => apply(),
                        ),
                      ),
                    DropdownButton<CommercialStage>(
                      hint: const Text('Todas las etapas'),
                      value: stage,
                      items: [
                        const DropdownMenuItem<CommercialStage>(
                          value: null,
                          child: Text('Todas las etapas'),
                        ),
                        for (final s in CommercialStage.values)
                          DropdownMenuItem(value: s, child: Text(s.label)),
                      ],
                      onChanged: (s) => setState(() => stage = s),
                    ),
                    DropdownButton<CommercialEvaluation>(
                      hint: const Text('Todas las evaluaciones'),
                      value: evaluation,
                      items: [
                        const DropdownMenuItem<CommercialEvaluation>(
                          value: null,
                          child: Text('Todas las evaluaciones'),
                        ),
                        for (final s in CommercialEvaluation.values)
                          DropdownMenuItem(value: s, child: Text(s.name)),
                      ],
                      onChanged: (s) => setState(() => evaluation = s),
                    ),
                    TextButton(
                      onPressed: () {
                        fields['responsibleId']!.text = 'UNASSIGNED';
                        apply();
                      },
                      child: const Text('Sin asignar'),
                    ),
                    FilledButton(
                      onPressed: apply,
                      child: const Text('Aplicar filtros'),
                    ),
                    TextButton(
                      onPressed: () {
                        for (final c in fields.values) {
                          c.clear();
                        }
                        stage = null;
                        evaluation = null;
                        apply();
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<SortField>(
              value: sort,
              items: [
                for (final s in [
                  SortField.name,
                  SortField.email,
                  SortField.status,
                  SortField.createdAt,
                  SortField.updatedAt,
                ])
                  DropdownMenuItem(value: s, child: Text('Orden: ${s.name}')),
              ],
              onChanged: (s) {
                if (s != null) {
                  sort = s;
                  apply();
                }
              },
            ),
            TextButton(
              onPressed: () {
                order = order == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
                apply();
              },
              child: Text(order.name),
            ),
            DropdownButton<int>(
              value: limit,
              items: [
                for (final n in [20, 50, 100])
                  DropdownMenuItem(value: n, child: Text('$n por página')),
              ],
              onChanged: (n) {
                if (n != null) {
                  limit = n;
                  apply();
                }
              },
            ),
            if (permissions?.canCreateProspects == true) ...[
              TextButton(
                onPressed: () => context.go('/prospects/new'),
                child: const Text('Nuevo prospecto'),
              ),
              TextButton(
                onPressed: () => context.go('/prospects/import'),
                child: const Text('Importar CSV'),
              ),
            ],
            IconButton(
              tooltip: 'Actualizar',
              onPressed: () =>
                  ref.invalidate(filteredCampaignProspectsProvider(key)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Expanded(
          child: ParticipationAsync(
            value: ref.watch(filteredCampaignProspectsProvider(key)),
            retry: () => ref.invalidate(filteredCampaignProspectsProvider(key)),
            data: (result) => Column(
              children: [
                Expanded(
                  child: result.items.isEmpty
                      ? const Center(
                          child: Text('No hay prospectos con estos filtros.'),
                        )
                      : ListView(
                          children: [
                            for (final row in result.items)
                              Card(
                                child: ListTile(
                                  title: Text(row.prospect.name),
                                  subtitle: Text(
                                    '${row.prospect.category ?? ''} · ${row.prospect.email ?? ''}\nEstado del maestro: ${row.prospect.status.name}\nEtapa comercial: ${row.participation.stage.label} · Evaluación: ${row.participation.evaluation.name}\nResponsable: ${row.participation.responsible?.name ?? 'Sin asignar'}${row.participation.responsible?.eligible == false ? ' (pendiente de reasignación)' : ''}',
                                  ),
                                  isThreeLine: true,
                                  onTap: () => showSessionDialog<void>(
                                    context: context,
                                    builder: (dialog) => AlertDialog(
                                      title: Text(row.prospect.name),
                                      content: SizedBox(
                                        width: 700,
                                        height: 600,
                                        child: ParticipationPanel((
                                          campaign: widget.campaign,
                                          prospect: row.prospect.id,
                                        )),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialog),
                                          child: const Text('Cerrar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(dialog);
                                            context.go(
                                              '/prospects/${row.prospect.id}',
                                            );
                                          },
                                          child: const Text('Ver maestro'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                ParticipationPagination(
                  meta: result.meta,
                  change: (n) => setState(() {
                    page = n;
                    query = pagination();
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
