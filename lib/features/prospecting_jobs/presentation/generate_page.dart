import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/campaign_picker.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../state/prospecting_jobs_providers.dart';

class GeneratePage extends ConsumerStatefulWidget {
  const GeneratePage({super.key});
  @override
  ConsumerState<GeneratePage> createState() => _GenerateState();
}

class _GenerateState extends ConsumerState<GeneratePage> {
  final form = GlobalKey<FormState>();
  final keyword = TextEditingController(),
      location = TextEditingController(),
      limit = TextEditingController(text: '20');
  Campaign? campaign;
  bool busy = false;
  String? error, requestSignature, requestKey;
  @override
  void dispose() {
    keyword.dispose();
    location.dispose();
    limit.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (campaign == null) {
      setState(() => error = 'Selecciona una campaña.');
      return;
    }
    final scope = ref.read(sessionScopeProvider);
    final signature =
        '${campaign!.id}\n${keyword.text.trim()}\n${location.text.trim()}\n${limit.text}';
    if (requestSignature != signature) {
      requestSignature = signature;
      requestKey = List.generate(
          24,
          (_) => Random.secure()
              .nextInt(256)
              .toRadixString(16)
              .padLeft(2, '0')).join();
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final job = await ref.read(prospectingJobsRepositoryProvider).create(
          CreateProspectingJobRequest(
              campaignId: campaign!.id,
              query: ProspectingQuery(
                  keyword: keyword.text.trim(),
                  location: location.text.trim(),
                  source: ProspectingSource.google_maps,
                  limit: int.parse(limit.text))),
          requestKey!);
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      ref.invalidate(jobsListProvider);
      ref.invalidate(dashboardProvider);
      context.go('/jobs/${job.id}');
    } catch (e) {
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      setState(() => error = e is ApiException &&
              e.kind == ApiErrorKind.serviceUnavailable
          ? 'El servicio de prospección no está disponible. Reintenta más tarde con los mismos datos.'
          : const ErrorMapper().userMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    return FeaturePage(
        title: 'Buscar prospectos',
        actions: [
          TextButton(
              onPressed: () => context.go('/jobs'),
              child: const Text('Ver trabajos'))
        ],
        child: PermissionGate(
            permissions: permissions,
            allowed: permissions.asData?.value.canRead == true,
            child: SingleChildScrollView(
                child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                        width: 640,
                        child: Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                      'Busca negocios en Google Maps y revisa los resultados antes de guardarlos en una campaña.'),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              final selected =
                                                  await pickCampaign(
                                                      context, ref);
                                              if (mounted && selected != null) {
                                                setState(
                                                    () => campaign = selected);
                                              }
                                            },
                                      child: Text(campaign?.name ??
                                          'Seleccionar campaña')),
                                  TextFormField(
                                      controller: keyword,
                                      enabled: !busy,
                                      decoration: const InputDecoration(
                                          labelText: 'Tipo de negocio'),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Escribe el tipo de negocio.'
                                              : null),
                                  TextFormField(
                                      controller: location,
                                      enabled: !busy,
                                      decoration: const InputDecoration(
                                          labelText: 'Ciudad o ubicación'),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Escribe la ubicación.'
                                              : null),
                                  TextFormField(
                                      controller: limit,
                                      enabled: !busy,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Máximo de resultados (1–100)'),
                                      validator: (v) {
                                        final n = int.tryParse(v ?? '');
                                        return n == null || n < 1 || n > 100
                                            ? 'Elige un número de 1 a 100.'
                                            : null;
                                      }),
                                  const SizedBox(height: 16),
                                  if (error != null)
                                    Text(error!,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error)),
                                  if (busy) const LinearProgressIndicator(),
                                  FilledButton(
                                      onPressed: busy ? null : submit,
                                      child: const Text('Iniciar búsqueda'))
                                ])))))));
  }
}
