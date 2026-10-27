import 'package:flutter/material.dart';

/// Presentation only. This component has no SDK, repository, Job or network state.
class ProspectingDemoPanel extends StatefulWidget {
  const ProspectingDemoPanel({super.key});

  @override
  State<ProspectingDemoPanel> createState() => _ProspectingDemoPanelState();
}

class _ProspectingDemoPanelState extends State<ProspectingDemoPanel> {
  int step = 0;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'DEMO — SIN EJECUCIÓN REAL',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            [
              'Ejemplo visual: definir una consulta de negocios y ubicación.',
              'En una integración futura, el Backend validaría la solicitud antes de enviarla al motor.',
              'Fin de la demostración. No se creó ningún trabajo ni se obtuvieron resultados.',
            ][step],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sin búsquedas, datos de negocio, guardado, exportación ni solicitudes de red.',
          ),
          TextButton(
            onPressed: () => setState(() => step = (step + 1) % 3),
            child: Text(
              step == 2 ? 'Reiniciar demostración' : 'Siguiente paso visual',
            ),
          ),
        ],
      ),
    ),
  );
}
