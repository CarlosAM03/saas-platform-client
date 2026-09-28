import 'package:flutter/material.dart';

import '../../dashboard/data/dashboard_mock_data.dart';
import 'campaign_status_badge.dart';


// TODO(backend): la card depende de CampaignSummaryMock. Cambiar a Campaign
// real (y quitar/ajustar las filas de stats) cuando el backend defina los datos.
class CampaignCard extends StatelessWidget {
  const CampaignCard({required this.summary, this.onTap, super.key});
  final CampaignSummaryMock summary;
  final VoidCallback? onTap;

  static String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = summary.campaign;
    final s = summary.stats;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            ),
            const SizedBox(width: 8),
            CampaignStatusBadge(c.status),
          ]),
          const SizedBox(height: 16),

          // TODO(backend): estas 3 filas (Prospectos/Contactados/Conversión) no
          // están en OpenAPI. Conservar, cambiar de fuente o eliminar según decisión.
          _StatRow('Prospectos', _n(s.prospects)),
          const SizedBox(height: 8),
          _StatRow('Contactados', _n(s.contacted)),
          const SizedBox(height: 8),
          _StatRow('Conversión', '${s.conversion.toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ver detalles'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: t.bodyMedium?.copyWith(color: const Color(0xFF475569))),
      Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
    ]);
  }
}