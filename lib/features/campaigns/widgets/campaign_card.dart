import 'package:flutter/material.dart';
import '../../../shared/widgets/beta_components.dart';
import '../../workspace/data/platform_repository.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({required this.campaign, required this.onTap, super.key});
  final Json campaign;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Surface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, children: [
          Text(campaign['name'] as String,
              style: Theme.of(context).textTheme.titleLarge),
          StatusBadge(campaign['status'] as String),
        ]),
        const SizedBox(height: 16),
        Text(
            campaign['description']?.toString().isNotEmpty == true
                ? campaign['description'] as String
                : 'Sin descripción',
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        Text('Actualizada el ${dateLabel(campaign['updatedAt'])}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver detalles'))),
      ]));
}
