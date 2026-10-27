import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
<<<<<<< Updated upstream
import '../../../shared/widgets/feature_widgets.dart';
import '../state/dashboard_providers.dart';
=======
import '../../../app/app_providers.dart';
import '../../../shared/widgets/beta_components.dart';
import '../../campaigns/widgets/campaign_card.dart';
import '../../workspace/data/platform_repository.dart';
>>>>>>> Stashed changes

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
<<<<<<< Updated upstream
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
      title: 'Dashboard',
      actions: [
        IconButton(
            tooltip: 'Actualizar dashboard',
            onPressed: () => ref.invalidate(dashboardProvider),
            icon: const Icon(Icons.refresh)),
        FilledButton.icon(
            onPressed: () => context.go('/generate'),
            icon: const Icon(Icons.travel_explore),
            label: const Text('Buscar prospectos'))
      ],
      child: AsyncPanel(
          value: ref.watch(dashboardProvider),
          retry: () => ref.invalidate(dashboardProvider),
          data: (data) => ListView(children: [
                const Text('Resumen de la organización actual'),
                const SizedBox(height: 16),
                Wrap(spacing: 16, runSpacing: 12, children: [
                  for (final item in [
                    (
                      'Campañas',
                      data.campaigns.meta.total,
                      '/campaigns',
                      Icons.campaign_outlined
                    ),
                    (
                      'Prospectos',
                      data.prospects.meta.total,
                      '/prospects',
                      Icons.people_outline
                    ),
                    (
                      'Trabajos',
                      data.jobs.meta.total,
                      '/jobs',
                      Icons.work_outline
                    )
                  ])
                    SizedBox(
                        width: 240,
                        child: Card(
                            child: ListTile(
                                leading: Icon(item.$4),
                                title: Text('${item.$2}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                subtitle: Text(item.$1),
                                onTap: () => context.go(item.$3))))
                ]),
                const SizedBox(height: 24),
                Text('Campañas recientes',
                    style: Theme.of(context).textTheme.titleLarge),
                if (data.campaigns.items.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aún no hay campañas.')),
                for (final campaign in data.campaigns.items)
                  Card(
                      child: ListTile(
                          title: Text(campaign.name),
                          subtitle:
                              Text(campaign.description ?? 'Sin descripción'),
                          trailing: Text(campaign.status.name),
                          onTap: () =>
                              context.go('/campaigns/${campaign.id}'))),
                const SizedBox(height: 24),
                Text('Trabajos recientes',
                    style: Theme.of(context).textTheme.titleLarge),
                if (data.jobs.items.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aún no hay trabajos de prospección.')),
                for (final job in data.jobs.items)
                  ListTile(
                      title: Text('Trabajo ${job.id}'),
                      subtitle: Text(job.createdAt.toLocal().toString()),
                      trailing: Text(job.status.name),
                      onTap: () => context.go('/jobs/${job.id}')),
              ])));
=======
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).context;
    if (session?.currentTenantId == null) {
      return PageBody(children: [
        PageHeading('Hola, ${session?.user.name ?? ''}',
            'Bienvenido a tu plataforma de campañas.'),
        StatePanel(
            title: 'Comienza con una organización',
            message:
                'Selecciona o crea tu espacio de trabajo para consultar campañas, prospectos y equipo.',
            icon: Icons.business_outlined,
            action: FilledButton(
                onPressed: () => context.go('/organizations'),
                child: const Text('Elegir organización'))),
      ]);
    }
    final data = ref.watch(dashboardProvider);
    return PageBody(children: [
      PageHeading('Hola, ${session!.user.name.split(' ').first}',
          'Esto es lo que está pasando en tu organización.',
          action: FilledButton.icon(
              onPressed: () => context.go('/campaigns/new'),
              icon: const Icon(Icons.add),
              label: const Text('Crear campaña'))),
      data.when(
          loading: () => const LoadingPanel(),
          error: (e, _) =>
              ErrorPanel(e, () => ref.invalidate(dashboardProvider)),
          data: (summary) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LayoutBuilder(
                    builder: (context, constraints) =>
                        Wrap(spacing: 16, runSpacing: 16, children: [
                          for (final metric in [
                            (
                              'Campañas',
                              summary.campaigns.meta.total,
                              Icons.campaign_outlined
                            ),
                            (
                              'Prospectos',
                              summary.prospects.meta.total,
                              Icons.people_outline
                            )
                          ])
                            SizedBox(
                                width: constraints.maxWidth < 560
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 16) / 2,
                                child: Surface(
                                    child: Row(children: [
                                  Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Icon(metric.$3,
                                          color: const Color(0xFF2563EB))),
                                  const SizedBox(width: 16),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(metric.$1),
                                        Text('${metric.$2}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge),
                                      ]),
                                ]))),
                        ])),
                const SizedBox(height: 32),
                Wrap(
                    spacing: 20,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Campañas recientes',
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                          onPressed: () => context.go('/campaigns'),
                          child: const Text('Ver todas')),
                      IconButton(
                          tooltip: 'Actualizar resumen',
                          onPressed: () => ref.invalidate(dashboardProvider),
                          icon: const Icon(Icons.refresh)),
                    ]),
                const SizedBox(height: 16),
                if (summary.campaigns.items.isEmpty)
                  StatePanel(
                      title: 'Tu primera campaña empieza aquí',
                      message: 'Crea una campaña para organizar tu trabajo.',
                      action: FilledButton(
                          onPressed: () => context.go('/campaigns/new'),
                          child: const Text('Crear campaña')))
                else
                  LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    return Wrap(spacing: 16, runSpacing: 16, children: [
                      for (final item in summary.campaigns.items)
                        SizedBox(
                            width:
                                (constraints.maxWidth - 16 * (cols - 1)) / cols,
                            child: CampaignCard(
                                campaign: item,
                                onTap: () =>
                                    context.go('/campaigns/${item['id']}'))),
                    ]);
                  }),
              ])),
    ]);
  }
>>>>>>> Stashed changes
}
