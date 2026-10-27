import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
<<<<<<< Updated upstream
import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/campaign_picker.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../../auth/state/tenant_permissions.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../state/prospecting_jobs_providers.dart';
=======
import '../../../shared/widgets/beta_components.dart';
import '../../workspace/data/platform_repository.dart';
>>>>>>> Stashed changes

class GeneratePage extends ConsumerStatefulWidget {
  const GeneratePage({super.key});
  @override
<<<<<<< Updated upstream
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
=======
  ConsumerState<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends ConsumerState<GeneratePage> {
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(jobsProvider(page));
    return PageBody(children: [
      const PageHeading(
          'Prospección', 'Consulta los trabajos de tu organización.'),
      const StatePanel(
          title: 'Generación automática próximamente',
          message:
              'En esta beta puedes consultar trabajos existentes y gestionar los prospectos guardados. La generación, cancelación y exportación estarán disponibles en una próxima versión.',
          icon: Icons.travel_explore_outlined),
      const SizedBox(height: 32),
      Text('Historial de trabajos',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(jobsProvider(page))),
          data: (result) => Column(children: [
                if (result.items.isEmpty)
                  const StatePanel(
                      title: 'Todavía no hay trabajos',
                      message:
                          'Aquí podrás consultar el historial de prospección.')
                else
                  Surface(
                      padding: 0,
                      child: Column(children: [
                        for (final item in result.items)
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                                'Trabajo · ${dateLabel(item['createdAt'])}'),
                            subtitle: const Text('Ver información del trabajo'),
                            trailing: StatusBadge(item['status'] as String),
                            onTap: () => context.go('/generate/${item['id']}'),
                          )
                      ])),
                PaginationBar(
                    result.meta, (number) => setState(() => page = number)),
                OutlinedButton.icon(
                    onPressed: () => ref.invalidate(jobsProvider(page)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar')),
              ])),
    ]);
  }
}

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(jobProvider(id));
    return PageBody(children: [
      TextButton.icon(
          onPressed: () => context.go('/generate'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Prospección')),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) => ErrorPanel(e, () => ref.invalidate(jobProvider(id))),
          data: (job) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const PageHeading('Detalle del trabajo',
                    'Información registrada de la prospección.'),
                StatusBadge(job['status'] as String),
                const SizedBox(height: 24),
                Surface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Búsqueda',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      SelectableText(
                          (job['query'] as Map?)?['keyword']?.toString() ??
                              'Sin información'),
                      const SizedBox(height: 8),
                      Text(
                          'Ubicación: ${(job['query'] as Map?)?['location'] ?? 'Sin información'}'),
                      const SizedBox(height: 20),
                      Text(
                          'Límite solicitado: ${job['requestedLimit'] ?? (job['query'] as Map?)?['limit'] ?? 'Sin información'}'),
                      const SizedBox(height: 8),
                      Text('Creado el ${dateLabel(job['createdAt'])}'),
                      if (job['startedAt'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Inicio: ${dateLabel(job['startedAt'])}')
                      ],
                      if (job['completedAt'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Finalización: ${dateLabel(job['completedAt'])}')
                      ],
                      const SizedBox(height: 16),
                      TextButton(
                          onPressed: () =>
                              context.go('/campaigns/${job['campaignId']}'),
                          child: const Text('Ver campaña')),
                    ])),
                const SizedBox(height: 24),
                const StatePanel(
                    title: 'Resultados no disponibles en esta beta',
                    message:
                        'El estado registrado del trabajo no implica que sus resultados puedan consultarse o exportarse.',
                    icon: Icons.info_outline),
                if (job['error'] != null) ...[
                  const SizedBox(height: 24),
                  Surface(
                      child: Text(
                          'El trabajo registró un error. Contacta al administrador para revisarlo.'))
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                    onPressed: () => ref.invalidate(jobProvider(id)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar')),
              ])),
    ]);
>>>>>>> Stashed changes
  }
}
