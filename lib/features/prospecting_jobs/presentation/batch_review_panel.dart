import 'package:flutter/material.dart';

import '../../../platform_api/platform_api.dart';

class BatchReviewPanel extends StatefulWidget {
  const BatchReviewPanel({
    required this.review,
    required this.busy,
    required this.confirm,
    super.key,
  });
  final BatchReview review;
  final bool busy;
  final Future<void> Function(List<BatchRowDecision> choices) confirm;

  @override
  State<BatchReviewPanel> createState() => _BatchReviewPanelState();
}

class _BatchReviewPanelState extends State<BatchReviewPanel> {
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
