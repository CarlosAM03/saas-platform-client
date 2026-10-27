import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../platform_api/platform_api.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/widgets/campaign_picker.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../data/prospect_import_repository.dart';
import '../state/prospects_providers.dart';

const importActions = {
  ProspectImportAction.CREATE: 'Crear prospecto',
  ProspectImportAction.LINK_EXISTING: 'Vincular sin modificar',
  ProspectImportAction.UPDATE_EXISTING: 'Actualizar y vincular',
  ProspectImportAction.SKIP: 'Omitir',
};
const importClasses = {
  ProspectImportClassification.NEW: 'Nuevo',
  ProspectImportClassification.MATCH: 'Coincidencia',
  ProspectImportClassification.INVALID: 'Inválido',
  ProspectImportClassification.CONFLICT: 'Conflicto',
};

class ProspectImportPage extends ConsumerStatefulWidget {
  const ProspectImportPage({super.key});
  @override
  ConsumerState<ProspectImportPage> createState() => _ImportState();
}

class _ImportState extends ConsumerState<ProspectImportPage> {
  Campaign? campaign;
  ApiUploadFile? upload;
  ProspectImportPreview? preview;
  ProspectImportResult? result;
  final decisions = <int, ProspectImportAction>{};
  bool busy = false, confirmationUncertain = false;
  String? error;

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final scope = ref.read(sessionScopeProvider);
    try {
      await task();
    } catch (e) {
      if (mounted && scope == ref.read(sessionScopeProvider)) {
        setState(
          () => error = e is ApiException && e.kind == ApiErrorKind.badRequest
              ? e.message
              : const ErrorMapper().userMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void clearPreview() {
    preview = null;
    result = null;
    confirmationUncertain = false;
    decisions.clear();
  }

  Future<void> generatePreview() => run(() async {
    final scope = ref.read(sessionScopeProvider);
    if (confirmationUncertain || campaign == null || upload == null) return;
    setState(clearPreview);
    final value = await ref
        .read(prospectImportRepositoryProvider)
        .preview(campaign!.id, upload!);
    if (!mounted || scope != ref.read(sessionScopeProvider)) return;
    setState(() {
      preview = value;
      for (final row in value.rows) {
        if (row.classification == ProspectImportClassification.NEW) {
          decisions[row.record] = ProspectImportAction.CREATE;
        } else if (row.classification == ProspectImportClassification.MATCH) {
          decisions[row.record] = ProspectImportAction.SKIP;
        }
      }
    });
  });

  Future<void> confirm() => run(() async {
    final scope = ref.read(sessionScopeProvider);
    final current = preview!;
    if (!current.expiresAt.isAfter(DateTime.now())) {
      setState(() {
        clearPreview();
        error = 'La vista previa venció. Genérala nuevamente.';
      });
      return;
    }
    final shared = current.rows
        .where(
          (row) =>
              decisions[row.record] == ProspectImportAction.UPDATE_EXISTING &&
              row.matches.any((m) => m.sharedWithOtherCampaigns),
        )
        .length;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Confirmar importación'),
        content: Text(
          'Se aplicarán las decisiones de ${decisions.length} filas. '
          'Las filas inválidas o en conflicto se rechazarán.'
          '${shared > 0 ? '\n\nActualizarás $shared prospectos compartidos. Sus cambios se reflejarán en las otras campañas.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Importar ahora'),
          ),
        ],
      ),
    );
    if (!mounted ||
        approved != true ||
        scope != ref.read(sessionScopeProvider)) {
      return;
    }
    try {
      final value = await ref
          .read(prospectImportRepositoryProvider)
          .confirm(
            campaign!.id,
            upload!,
            current.previewReference,
            decisions.entries
                .map(
                  (e) => ProspectImportDecision(record: e.key, action: e.value),
                )
                .toList(),
          );
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      ref.invalidate(prospectsListProvider);
      ref.invalidate(prospectsDetailProvider);
      ref.invalidate(campaignProspectsProvider);
      ref.invalidate(dashboardProvider);
      setState(() {
        result = value;
        preview = null;
      });
    } catch (e) {
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      setState(() {
        preview = null;
        confirmationUncertain =
            !(e is ApiException &&
                (e.kind == ApiErrorKind.badRequest ||
                    e.kind == ApiErrorKind.conflict ||
                    e.kind == ApiErrorKind.forbidden ||
                    e.kind == ApiErrorKind.unauthorized ||
                    e.kind == ApiErrorKind.notFound ||
                    e.kind == ApiErrorKind.payloadTooLarge));
        error =
            e is ApiException &&
                (e.kind == ApiErrorKind.badRequest ||
                    e.kind == ApiErrorKind.conflict)
            ? 'La vista previa venció o los datos cambiaron. Genera una nueva vista previa.'
            : 'No se pudo confirmar el resultado. Revisa los prospectos de la campaña antes de generar otra vista previa. ${const ErrorMapper().userMessage(e)}';
      });
    }
  });

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    return FeaturePage(
      title: 'Importar prospectos CSV',
      actions: [
        TextButton(
          onPressed: busy ? null : () => context.go('/prospects'),
          child: const Text('Volver a prospectos'),
        ),
      ],
      child: PermissionGate(
        permissions: permissions,
        allowed: permissions.asData?.value.canCreateProspects == true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    '1. Elige la campaña y el archivo\n2. Revisa las filas y coincidencias\n3. Confirma la importación',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CSV UTF-8 · hasta 5 MB y 1,000 registros · encabezado name obligatorio. '
                    'Opcionales: category, address, phone, email, website, language, status. '
                    'Una celda vacía puede borrar el valor existente al actualizar.',
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                final value = await pickCampaign(context, ref);
                                if (mounted && value != null) {
                                  setState(() {
                                    campaign = value;
                                    clearPreview();
                                  });
                                }
                              }),
                        child: Text(campaign?.name ?? 'Seleccionar campaña'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: Text(upload?.filename ?? 'Seleccionar CSV'),
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                final value = await ref
                                    .read(fileServiceProvider)
                                    .pickCsv();
                                if (mounted && value != null) {
                                  setState(() {
                                    upload = value;
                                    clearPreview();
                                  });
                                }
                              }),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                await ref
                                    .read(fileServiceProvider)
                                    .save(
                                      'plantilla-prospectos.csv',
                                      utf8.encode(
                                        'name,category,address,phone,email,website,language,status\r\n'
                                        'Negocio de ejemplo,Cafetería,Calle Principal 123,0012345,,,es,ACTIVO\r\n',
                                      ),
                                    );
                              }),
                        child: const Text('Descargar plantilla'),
                      ),
                    ],
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (confirmationUncertain) ...[
                    TextButton(
                      onPressed: () => context.go('/campaigns/${campaign!.id}'),
                      child: const Text('Revisar prospectos de la campaña'),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : () => setState(clearPreview),
                      child: const Text(
                        'Ya revisé el resultado; preparar otra importación',
                      ),
                    ),
                  ],
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                  if (result case final value?) ...[
                    Text(
                      'Importación terminada',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${value.summary.created} creados · ${value.summary.linked} vinculados · '
                      '${value.summary.updated} actualizados · ${value.summary.skipped} omitidos · ${value.summary.rejected} rechazados',
                    ),
                    TextButton(
                      onPressed: () => context.go('/campaigns/${campaign!.id}'),
                      child: const Text('Ver prospectos de la campaña'),
                    ),
                    for (final row in value.rows.where(
                      (r) => r.action == ProspectImportResultAction.REJECTED,
                    ))
                      ListTile(
                        title: Text('Fila ${row.record}: rechazada'),
                        subtitle: Text(
                          row.errors
                              .map((e) => '${e.field}: ${e.message}')
                              .join('\n'),
                        ),
                      ),
                  ],
                  if (preview case final value?) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${value.summary.total} filas · ${value.summary.newCount} nuevas · ${value.summary.matches} coincidencias · '
                      '${value.summary.invalid} inválidas · ${value.summary.conflicts} conflictos',
                    ),
                    Text(
                      'Vista previa válida hasta ${value.expiresAt.toLocal()}',
                    ),
                    const Text(
                      'Las coincidencias se omiten hasta que elijas vincularlas o actualizarlas.',
                    ),
                    for (final row in value.rows)
                      Card(
                        child: ExpansionTile(
                          key: ValueKey('import-row-${row.record}'),
                          title: Text('${row.record}. ${row.values.name}'),
                          subtitle: Text(importClasses[row.classification]!),
                          childrenPadding: const EdgeInsets.all(12),
                          children: [
                            for (final field in {
                              'name': row.values.name,
                              'category': row.values.category,
                              'address': row.values.address,
                              'phone': row.values.phone,
                              'email': row.values.email,
                              'website': row.values.website,
                              'language': row.values.language,
                              'status': row.values.status?.name,
                            }.entries)
                              if (row.values.presentFields.contains(field.key))
                                ListTile(
                                  dense: true,
                                  title: Text(field.key),
                                  subtitle: Text(field.value ?? '(vacío)'),
                                ),
                            for (final e in row.errors)
                              Text('${e.field}: ${e.message}'),
                            if (row.classification ==
                                ProspectImportClassification.CONFLICT)
                              const Text(
                                'Hay varios candidatos. Corrige el archivo y genera otra vista previa.',
                              ),
                            for (final match in row.matches) ...[
                              Text('Prospecto existente: ${match.id}'),
                              if (match.sharedWithOtherCampaigns)
                                const Text('Compartido con otras campañas'),
                              for (final diff in match.differences)
                                Text(
                                  '${diff.field}: ${diff.existing ?? '(vacío)'} → ${diff.imported ?? '(vacío)'}',
                                ),
                            ],
                            if (decisions.containsKey(row.record))
                              DropdownButton<ProspectImportAction>(
                                isExpanded: true,
                                value: decisions[row.record],
                                items:
                                    (row.classification ==
                                                ProspectImportClassification.NEW
                                            ? [
                                                ProspectImportAction.CREATE,
                                                ProspectImportAction.SKIP,
                                              ]
                                            : [
                                                ProspectImportAction.SKIP,
                                                ProspectImportAction
                                                    .LINK_EXISTING,
                                                ProspectImportAction
                                                    .UPDATE_EXISTING,
                                              ])
                                        .map(
                                          (a) => DropdownMenuItem(
                                            value: a,
                                            child: Text(importActions[a]!),
                                          ),
                                        )
                                        .toList(),
                                onChanged: busy
                                    ? null
                                    : (action) => setState(
                                        () => decisions[row.record] = action!,
                                      ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed:
                      busy ||
                          confirmationUncertain ||
                          upload == null ||
                          campaign == null ||
                          result != null
                      ? null
                      : generatePreview,
                  child: Text(
                    preview == null
                        ? 'Generar vista previa'
                        : 'Regenerar vista previa',
                  ),
                ),
                FilledButton(
                  onPressed: busy || preview == null || decisions.isEmpty
                      ? null
                      : confirm,
                  child: const Text('Confirmar importación'),
                ),
                if (result != null)
                  TextButton(
                    onPressed: () => setState(() {
                      clearPreview();
                      upload = null;
                    }),
                    child: const Text('Otra importación'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
