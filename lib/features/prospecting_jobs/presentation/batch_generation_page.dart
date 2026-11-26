import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/campaign_picker.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../campaigns/state/campaigns_providers.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../../prospects/state/prospects_providers.dart';
import '../state/batch_providers.dart';
import 'batch_detail_view.dart';
import 'batch_labels.dart';

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
      final value = await action(ref.read(batchApiProvider));
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
      selected = batch;
      ref.invalidate(batchHistoryProvider);
    }, admission: true);
  }

  void invalidateAfterMutation() {
    ref.invalidate(batchHistoryProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(prospectsListProvider);
    ref.invalidate(campaignProspectsProvider);
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
                .watch(batchHistoryProvider(page))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (problem, _) => TextButton(
                    onPressed: () => ref.invalidate(batchHistoryProvider(page)),
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
                          subtitle: Text(batchAdmissionLabel(batch.admission)),
                          onTap: busy
                              ? null
                              : () => setState(() => selected = batch),
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
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: busy
              ? null
              : () => setState(() {
                  selected = null;
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
      ),
      BatchDetailView(
        key: ValueKey(batch.id),
        batch: batch,
        onUpdated: (value) => setState(() => selected = value),
        onMutated: invalidateAfterMutation,
      ),
    ],
  );
}
