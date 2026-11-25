import 'package:flutter/material.dart';

import '../../../platform_api/platform_api.dart';
import '../../../shared/widgets/catalog_list.dart';

class CampaignStatusBadge extends StatelessWidget {
  const CampaignStatusBadge(this.status, {super.key});
  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      CampaignStatus.ACTIVA => ('Activa', CatalogTagTone.positive),
      CampaignStatus.PAUSADA => ('Pausada', CatalogTagTone.paused),
      CampaignStatus.COMPLETADA => ('Completada', CatalogTagTone.info),
      CampaignStatus.ARCHIVADA => ('Archivada', CatalogTagTone.neutral),
    };
    return CatalogTag(label, tone: tone);
  }
}
