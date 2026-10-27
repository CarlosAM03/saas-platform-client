import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../auth/state/tenant_permissions.dart';

class ProspectingCapabilities {
  const ProspectingCapabilities({
    this.create = false,
    this.cancel = false,
    this.persist = false,
    this.export = false,
    this.reason,
  });
  final bool create, cancel, persist, export;
  final String? reason;
}

/// Session-scoped verification. Unknown contract/network/404 always falls back closed.
final verifiedProspectingCapabilitiesProvider =
    FutureProvider.autoDispose<ProspectingCapabilities>((ref) async {
      final scope = ref.watch(sessionScopeProvider);
      if (scope?.tenantId == null) return const ProspectingCapabilities();
      try {
        final status = await ref
            .watch(platformApiProvider)
            .prospectingJobs
            .capabilities();
        return ProspectingCapabilities(
          create: status.create,
          reason: status.reason,
        );
      } catch (_) {
        return const ProspectingCapabilities(
          reason: 'PROSPECTOR_VERIFICATION_FAILED',
        );
      }
    });
final prospectingCapabilitiesProvider =
    Provider.autoDispose<ProspectingCapabilities>(
      (ref) =>
          ref.watch(verifiedProspectingCapabilitiesProvider).asData?.value ??
          const ProspectingCapabilities(),
    );
const pendingProspectorMessage =
    'La creación requiere disponibilidad y cuota verificadas en el Backend. Cancelar, guardar resultados en campaña y exportar trabajos no están disponibles. La importación CSV continúa disponible.';
String prospectingUnavailableMessage(String? reason) => switch (reason) {
  'PROSPECTOR_INTEGRATION_PENDING' =>
    'La generación automática de prospectos aún no está disponible en esta instancia. Puedes gestionar campañas e importar prospectos mediante CSV.',
  'PROSPECTOR_POLICY_NOT_CONFIGURED' =>
    'La generación automática está pendiente de configuración. Puedes gestionar campañas e importar prospectos mediante CSV.',
  'PROSPECTOR_VERIFICATION_FAILED' =>
    'No fue posible verificar la disponibilidad de generación. Puedes consultar campañas e importar prospectos mediante CSV.',
  'TENANT_QUOTA_EXHAUSTED' || 'GLOBAL_QUOTA_EXHAUSTED' =>
    'Se agotó la cuota de búsquedas. Espera a que se renueve el periodo.',
  'PROSPECTOR_CAPACITY_EXHAUSTED' =>
    'La capacidad de búsqueda está ocupada. Puedes consultar los trabajos existentes.',
  'PROSPECTOR_SERVICE_UNAVAILABLE' =>
    'El servicio de prospección no está disponible. Puedes volver a verificar.',
  _ => pendingProspectorMessage,
};
