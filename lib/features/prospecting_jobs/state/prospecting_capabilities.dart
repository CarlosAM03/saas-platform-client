import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Verified against NestJS 967044e: reads are supported; mutations return 503.
/// Enable individual actions only after verifying a newer backend contract.
class ProspectingCapabilities {
  const ProspectingCapabilities({
    this.create = false,
    this.cancel = false,
    this.persist = false,
    this.export = false,
  });
  final bool create, cancel, persist, export;
}

final prospectingCapabilitiesProvider = Provider<ProspectingCapabilities>(
  (ref) => const ProspectingCapabilities(),
);
const pendingProspectorMessage =
    'La integración de prospección está pendiente en el Backend. '
    'Puedes consultar el historial y el detalle de trabajos existentes; iniciar, cancelar, guardar y exportar no están disponibles.';
