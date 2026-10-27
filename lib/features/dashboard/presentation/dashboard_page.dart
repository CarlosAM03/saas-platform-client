import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/feature_widgets.dart';
import '../state/dashboard_providers.dart';
import '../../campaigns/widgets/campaign_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
    title: 'Dashboard',
    actions: [
      IconButton(
        tooltip: 'Actualizar dashboard',
        onPressed: () => ref.invalidate(dashboardProvider),
        icon: const Icon(Icons.refresh),
      ),
      FilledButton.icon(
        onPressed: () => context.go('/generate'),
        icon: const Icon(Icons.travel_explore),
        label: const Text('Buscar prospectos'),
      ),
    ],
    child: AsyncPanel(
      value: ref.watch(dashboardProvider),
      retry: () => ref.invalidate(dashboardProvider),
      data: (data) => ListView(
        children: [
          const Text('Resumen de la organización actual'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final item in [
                (
                  'Campañas',
                  data.campaigns.meta.total,
                  '/campaigns',
                  Icons.campaign_outlined,
                ),
                (
                  'Prospectos',
                  data.prospects.meta.total,
                  '/prospects',
                  Icons.people_outline,
                ),
                ('Trabajos', data.jobs.meta.total, '/jobs', Icons.work_outline),
              ])
                SizedBox(
                  width: 240,
                  child: Card(
                    child: ListTile(
                      leading: Icon(item.$4),
                      title: Text(
                        '${item.$2}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      subtitle: Text(item.$1),
                      onTap: () => context.go(item.$3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Campañas recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (data.campaigns.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay campañas.'),
            ),
          for (final campaign in data.campaigns.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CampaignCard(
                campaign: campaign,
                onTap: () => context.go('/campaigns/${campaign.id}'),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Prospectos recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (data.prospects.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay prospectos.'),
            ),
          for (final prospect in data.prospects.items)
            ListTile(
              title: Text(prospect.name),
              subtitle: Text(
                prospect.email ?? prospect.phone ?? 'Sin contacto',
              ),
              onTap: () => context.go('/prospects/${prospect.id}'),
            ),
          const SizedBox(height: 24),
          Text(
            'Trabajos recientes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (data.jobs.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay trabajos de prospección.'),
            ),
          for (final job in data.jobs.items)
            ListTile(
              title: Text('Trabajo ${job.id}'),
              subtitle: Text(job.createdAt.toLocal().toString()),
              trailing: Text(job.status.name),
              onTap: () => context.go('/jobs/${job.id}'),
            ),
        ],
      ),
    ),
  );
}
