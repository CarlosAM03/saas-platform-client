import '../../../platform_api/platform_api.dart';

String batchAdmissionLabel(BatchAdmission status) => switch (status) {
  BatchAdmission.PENDING => 'Solicitud registrada, admisión pendiente',
  BatchAdmission.UNCERTAIN => 'Admisión sin confirmar',
  BatchAdmission.ACCEPTED => 'Lote admitido',
  BatchAdmission.REJECTED => 'Lote rechazado',
};

String batchJobLabel(BatchJobState? state) => switch (state) {
  null => 'Sin estado confirmado',
  BatchJobState.QUEUED => 'En cola',
  BatchJobState.RUNNING => 'En ejecución',
  BatchJobState.AWAITING_RESULTS => 'Esperando resultados',
  BatchJobState.COMPLETED => 'Completada',
  BatchJobState.FAILED => 'Fallida',
  BatchJobState.INTERRUPTED => 'Interrumpida',
  BatchJobState.SKIPPED => 'Omitida',
};

String batchAvailabilityLabel(BatchAvailability status) => switch (status) {
  BatchAvailability.AVAILABLE => 'Resultados disponibles',
  BatchAvailability.EXPIRED => 'Resultados vencidos',
  BatchAvailability.PURGED => 'Resultados purgados',
  BatchAvailability.UNAVAILABLE => 'Resultados no disponibles',
};
