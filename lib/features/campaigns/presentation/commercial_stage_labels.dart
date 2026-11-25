import '../../../platform_api/campaign_participation_models.dart';

extension CommercialStageLabel on CommercialStage {
  String get label => switch (this) {
    CommercialStage.SIN_GESTIONAR => 'Sin gestionar',
    CommercialStage.EN_INVESTIGACION => 'En investigación',
    CommercialStage.CONTACTADO => 'Contactado',
    CommercialStage.EN_SEGUIMIENTO => 'En seguimiento',
    CommercialStage.OPORTUNIDAD => 'Oportunidad',
    CommercialStage.CERRADO => 'Cerrado',
  };
}

String commercialStageLabelForCode(String code) {
  for (final stage in CommercialStage.values) {
    if (stage.name == code) return stage.label;
  }
  return code;
}
