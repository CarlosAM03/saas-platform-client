import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_state_view.dart';
import '../../campaigns/widgets/campaign_card.dart';
import '../data/dashboard_mock_data.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(dashboardCampaignsProvider);
    final items = campaigns.valueOrNull ?? const <CampaignSummaryMock>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Campañas recientes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          // AsyncStateView centra sus estados; damos altura mínima para ellos.
          child: campaigns.isLoading || campaigns.hasError || items.isEmpty
              ? SizedBox(
                  height: 200,
                  child: AsyncStateView(
                    loading: campaigns.isLoading,
                    empty: items.isEmpty,
                    error: campaigns.hasError ? campaigns.error : null,
                    success: const SizedBox.shrink(),
                  ),
                )
              : _CampaignGrid(items: items),
        ),
      ]),
    );
  }
}

class _CampaignGrid extends StatelessWidget {
  const _CampaignGrid({required this.items});
  final List<CampaignSummaryMock> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 16.0;
      final w = constraints.maxWidth;
      final cols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
      final cardWidth = (w - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: cardWidth,
              child: CampaignCard(
                summary: item,
                // Aún no existe ruta de detalle; por ahora lleva a Campañas.
                // TODO(backend): aún no existe ruta de detalle de campaña.
                // Navegar a /campaigns/:id cuando se implemente esa pantalla.
                onTap: () => context.go('/campaigns'),
              ),
            ),
        ],
      );
    });
  }
}