enum CampaignStatus { activa, pausada, completada, archivada }

class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final CampaignStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}