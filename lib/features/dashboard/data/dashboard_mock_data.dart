import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campaigns/models/campaign.dart';

// TODO(backend): CampaignStatsMock completo es provisional. Prospectos,
// Contactados y Conversión NO existen en OpenAPI. Definir con Ángel de dónde
// salen; si no habrá endpoint, eliminar la sección de estadísticas de la card.
class CampaignStatsMock {
  const CampaignStatsMock({
    required this.prospects,
    required this.contacted,
    required this.conversion,
  });
  final int prospects;
  final int contacted;
  final double conversion; // porcentaje
}

// TODO(backend): CampaignSummaryMock es un envoltorio temporal (campaña + stats).
// Reemplazar por el DTO real de GET /api/v1/campaigns cuando exista.
class CampaignSummaryMock {
  const CampaignSummaryMock(this.campaign, this.stats);
  final Campaign campaign;
  final CampaignStatsMock stats;
}

// TODO(backend): datos y delay hardcodeados. Reemplazar por un
// CampaignsRepository (API) que llame a GET /api/v1/campaigns.
final dashboardCampaignsProvider =
    FutureProvider<List<CampaignSummaryMock>>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final now = DateTime.now();
  return [
    CampaignSummaryMock(
      Campaign(id: 'mock-1', name: 'Campaña Verano 2026', status: CampaignStatus.activa, createdAt: now, updatedAt: now),
      const CampaignStatsMock(prospects: 1240, contacted: 380, conversion: 12.4),
    ),
    CampaignSummaryMock(
      Campaign(id: 'mock-2', name: 'Campaña B2B', status: CampaignStatus.pausada, createdAt: now, updatedAt: now),
      const CampaignStatsMock(prospects: 530, contacted: 210, conversion: 8.1),
    ),
    CampaignSummaryMock(
      Campaign(id: 'mock-3', name: 'Lanzamiento Otoño', status: CampaignStatus.completada, createdAt: now, updatedAt: now),
      const CampaignStatsMock(prospects: 860, contacted: 860, conversion: 15.7),
    ),
  ];
});