import 'package:flutter/material.dart';
import '../../../shared/widgets/beta_components.dart';
import '../../../platform_api/platform_api.dart';
import 'campaign_status_badge.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({required this.campaign, required this.onTap, super.key});
  final Campaign campaign;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(campaign.name, style: Theme.of(context).textTheme.titleLarge),
            CampaignStatusBadge(campaign.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          campaign.description?.isNotEmpty == true
              ? campaign.description!
              : 'Sin descripción',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Actualizada el ${dateLabel(campaign.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Ver detalles'),
          ),
        ),
      ],
    ),
  );
}

class CampaignCards extends StatelessWidget {
  const CampaignCards({
    required this.campaigns,
    required this.onSelected,
    super.key,
  });
  final List<Campaign> campaigns;
  final ValueChanged<Campaign> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final campaign in campaigns)
            SizedBox(
              width: (constraints.maxWidth - 16 * (cols - 1)) / cols,
              child: CampaignCard(
                campaign: campaign,
                onTap: () => onSelected(campaign),
              ),
            ),
        ],
      );
    },
  );
}
