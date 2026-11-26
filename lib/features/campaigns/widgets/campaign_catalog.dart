import 'package:flutter/material.dart';

import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/beta_components.dart' show dateLabel;
import '../../../shared/widgets/catalog_list.dart';
import 'campaign_status_badge.dart';

class CampaignCatalog extends StatelessWidget {
  const CampaignCatalog({
    required this.campaigns,
    required this.onSelected,
    super.key,
  });

  final List<Campaign> campaigns;
  final ValueChanged<Campaign> onSelected;

  @override
  Widget build(BuildContext context) => CatalogList(
    titleLabel: 'Campaña',
    columns: const ['Estado', 'Actualizada'],
    actionLabel: 'Ver detalles',
    records: [
      for (final campaign in campaigns)
        CatalogRecord(
          title: campaign.name,
          description: campaign.description,
          cells: [
            CampaignStatusBadge(campaign.status),
            Text(dateLabel(campaign.updatedAt)),
          ],
          open: () => onSelected(campaign),
        ),
    ],
  );
}
