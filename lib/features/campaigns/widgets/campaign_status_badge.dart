import 'package:flutter/material.dart';

import '../models/campaign.dart';

class CampaignStatusBadge extends StatelessWidget {
  const CampaignStatusBadge(this.status, {super.key});
  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CampaignStatus.activa => ('Activa', const Color(0xFF16A34A)),
      CampaignStatus.pausada => ('Pausada', const Color(0xFFD97706)),
      CampaignStatus.completada => ('Completada', const Color(0xFF2563EB)),
      CampaignStatus.archivada => ('Archivada', const Color(0xFF64748B)),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, size: 10, color: color),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}