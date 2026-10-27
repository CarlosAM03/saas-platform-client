import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/campaign_picker.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../state/prospecting_jobs_providers.dart';
import '../state/prospecting_capabilities.dart';

class GeneratePage extends ConsumerStatefulWidget {
  const GeneratePage({super.key, this.retryJobId});
  final String? retryJobId;
  @override
  ConsumerState<GeneratePage> createState() => _GenerateState();
}

class _GenerateState extends ConsumerState<GeneratePage> {
  final form = GlobalKey<FormState>();
  final keyword = TextEditingController(),
      location = TextEditingController(),
      limit = TextEditingController(text: '20');
  Campaign? campaign;
  bool busy = false,
      uncertain = false,
      retryLoading = false,
      confirming = false;
  DialogRoute<bool>? confirmationRoute;
  String? error, requestSignature, requestKey, uncertainJobId;
  @override
  void initState() {
    super.initState();
    if (widget.retryJobId != null) {
      retryLoading = true;
      Future<void>.microtask(loadRetry);
    }
  }

  Future<void> loadRetry() async {
    final scope = ref.read(sessionScopeProvider);
    try {
      final job = await ref
          .read(prospectingJobsRepositoryProvider)
          .get(widget.retryJobId!);
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      if (job.status != ProspectingJobStatus.FAILED || !job.retryAllowed) {
        throw StateError(
          'La ejecución anterior no permite una repetición segura. Consulta su detalle.',
        );
      }
      final selected = await ref
          .read(platformApiProvider)
          .campaigns
          .get(job.campaignId);
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      setState(() {
        campaign = selected;
        keyword.text = job.query.keyword;
        location.text = job.query.location;
        limit.text = job.query.limit.toString();
      });
    } catch (e) {
      if (mounted && scope == ref.read(sessionScopeProvider)) {
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : const ErrorMapper().userMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => retryLoading = false);
    }
  }

  @override
  void dispose() {
    final route = confirmationRoute;
    if (route != null) {
      Future<void>.microtask(() {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    keyword.dispose();
    location.dispose();
    limit.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy ||
        retryLoading ||
        (!uncertain && !ref.read(prospectingCapabilitiesProvider).create) ||
        !form.currentState!.validate()) {
      return;
    }
    if (campaign == null) {
      setState(() => error = 'Selecciona una campaña.');
      return;
    }
    final scope = ref.read(sessionScopeProvider);
    final request = CreateProspectingJobRequest(
      campaignId: campaign!.id,
      query: ProspectingQuery(
        keyword: keyword.text.trim(),
        location: location.text.trim(),
        source: ProspectingSource.google_maps,
        limit: int.parse(limit.text),
      ),
    );
    setState(() {
      busy = true;
      confirming = true;
      error = null;
    });
    try {
      final route = DialogRoute<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(
            uncertain ? 'Consultar la misma solicitud' : 'Confirmar búsqueda',
          ),
          content: Text(
            uncertain
                ? 'Se conservarán los datos y la clave de la solicitud incierta. El Backend consultará esa intención sin reenviar la búsqueda.'
                : 'Buscar hasta ${request.query.limit} negocios en ${request.query.location}. Los resultados estarán disponibles durante una hora y no se guardarán automáticamente en la campaña.',
          ),
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
      );
      confirmationRoute = route;
      final confirmed = await Navigator.of(
        context,
        rootNavigator: true,
      ).push(route);
      confirmationRoute = null;
      if (!mounted ||
          scope != ref.read(sessionScopeProvider) ||
          confirmed != true) {
        return;
      }
      setState(() => confirming = false);
      final signature = jsonEncode(request.toJson());
      if (requestSignature != signature) {
        requestSignature = signature;
        requestKey = List.generate(
          24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
      }
      final job = await ref
          .read(prospectingJobsRepositoryProvider)
          .create(request, requestKey!);
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      ref.invalidate(jobsListProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(verifiedProspectingCapabilitiesProvider);
      context.go('/jobs/${job.id}');
    } catch (e) {
      if (!mounted || scope != ref.read(sessionScopeProvider)) return;
      final details = e is ApiException && e.details is Map
          ? e.details as Map
          : const <String, Object?>{};
      final reason = details['reason'];
      final definitive =
          e is ApiException &&
          ({
                ApiErrorKind.badRequest,
                ApiErrorKind.unauthorized,
                ApiErrorKind.forbidden,
                ApiErrorKind.notFound,
                ApiErrorKind.conflict,
                ApiErrorKind.payloadTooLarge,
                ApiErrorKind.rateLimited,
              }.contains(e.kind) ||
              (e.kind == ApiErrorKind.serviceUnavailable &&
                  {
                    'PROSPECTOR_INTEGRATION_PENDING',
                    'PROSPECTOR_POLICY_NOT_CONFIGURED',
                    'PROSPECTOR_SERVICE_UNAVAILABLE',
                    'PROSPECTOR_SERVICE_REJECTED',
                    'PROSPECTOR_CAPACITY_EXHAUSTED',
                    'PROSPECTOR_TENANT_ID_UNSUPPORTED',
                  }.contains(reason)));
      if (definitive) {
        requestSignature = null;
        requestKey = null;
        ref.invalidate(verifiedProspectingCapabilitiesProvider);
      }
      final id = details['jobId'];
      setState(() {
        uncertain = !definitive;
        uncertainJobId =
            id is String && RegExp(r'^c[a-z0-9]{20,}$').hasMatch(id)
            ? id
            : null;
        error = uncertain
            ? 'No se pudo confirmar la aceptación. Conservamos la clave y los datos; revisa el trabajo o el historial antes de iniciar otra búsqueda. No se repetirá el scraping automáticamente.'
            : e is ApiException && e.kind == ApiErrorKind.serviceUnavailable
            ? 'El servicio de prospección no está disponible. ${prospectingUnavailableMessage(reason is String ? reason : null)}'
            : e is ApiException && e.kind == ApiErrorKind.rateLimited
            ? prospectingUnavailableMessage(reason is String ? reason : null)
            : e is ApiException && e.kind == ApiErrorKind.notFound
            ? 'No se encontró una campaña disponible en esta organización.'
            : const ErrorMapper().userMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(currentTenantPermissionsProvider);
    final capabilities = ref.watch(prospectingCapabilitiesProvider);
    if (!capabilities.create && !uncertain) {
      return FeaturePage(
        title: 'Generación automática no disponible',
        actions: [
          TextButton(
            onPressed: () => context.go('/jobs'),
            child: const Text('Ver trabajos'),
          ),
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(prospectingUnavailableMessage(capabilities.reason)),
                if (error != null) Text(error!),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(verifiedProspectingCapabilitiesProvider),
                  child: const Text('Verificar disponibilidad'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final editable = !busy && !uncertain && !retryLoading;
    return FeaturePage(
      title: 'Buscar prospectos',
      actions: [
        TextButton(
          onPressed: () => context.go('/jobs'),
          child: const Text('Ver trabajos'),
        ),
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
                      'Busca negocios en Google Maps. Los resultados son temporales; guardar en campaña y exportar no están disponibles.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: !editable
                          ? null
                          : () async {
                              final selected = await pickCampaign(context, ref);
                              if (mounted && selected != null) {
                                setState(() => campaign = selected);
                              }
                            },
                      child: Text(campaign?.name ?? 'Seleccionar campaña'),
                    ),
                    TextFormField(
                      controller: keyword,
                      enabled: editable,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de negocio',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe el tipo de negocio.'
                          : null,
                    ),
                    TextFormField(
                      controller: location,
                      enabled: editable,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad o ubicación',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe la ubicación.'
                          : null,
                    ),
                    TextFormField(
                      controller: limit,
                      enabled: editable,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Máximo de resultados (1–100)',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 1 || n > 100
                            ? 'Elige un número de 1 a 100.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (uncertainJobId != null)
                      TextButton(
                        onPressed: () => context.go('/jobs/${uncertainJobId!}'),
                        child: const Text('Consultar trabajo incierto'),
                      ),
                    if ((busy && !confirming) || retryLoading)
                      const LinearProgressIndicator(),
                    FilledButton(
                      onPressed: busy || retryLoading ? null : submit,
                      child: Text(
                        uncertain
                            ? 'Consultar misma solicitud'
                            : 'Iniciar búsqueda',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
