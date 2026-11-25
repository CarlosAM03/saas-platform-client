import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/api_exception.dart';
import '../../../platform_api/platform_api.dart' show Prospect;
import '../../../platform_api/prospect_context_api.dart';
import '../../../shared/widgets/session_dialog.dart';
import '../../auth/state/tenant_permissions.dart';
import '../state/prospect_context_providers.dart';

Future<Prospect?> verifyAndCreateProspect(
  BuildContext context,
  WidgetRef ref,
  ProspectIntakeRequest request,
) async {
  final scope = ref.read(sessionScopeProvider);
  final repository = ref.read(prospectContextRepositoryProvider);
  while (context.mounted && scope == ref.read(sessionScopeProvider)) {
    final match = await repository.match(request);
    if (!context.mounted || scope != ref.read(sessionScopeProvider)) {
      return null;
    }
    final choice =
        await showSessionDialog<
          ({ProspectResolution resolution, String? candidate})
        >(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Verificación de coincidencias'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (match.strongProspect != null)
                      Text(
                        'Se reutilizará el prospecto existente: ${match.strongProspect!.name}',
                      )
                    else if (match.candidates.isEmpty)
                      const Text(
                        'No se encontraron coincidencias. Se creará un prospecto nuevo.',
                      )
                    else
                      const Text(
                        'Hay coincidencias posibles. Elige explícitamente cómo continuar.',
                      ),
                    if (match.strongProspect == null)
                      for (final p in match.candidates)
                        ListTile(
                          title: Text(p.name),
                          subtitle: Text(p.email ?? p.phone ?? p.id),
                          trailing: TextButton(
                            onPressed: () => Navigator.pop(dialog, (
                              resolution: ProspectResolution.linkExisting,
                              candidate: p.id,
                            )),
                            child: const Text('Vincular'),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cancelar'),
              ),
              if (match.strongProspect == null && match.resolutionRequired)
                TextButton(
                  onPressed: () => Navigator.pop(dialog, (
                    resolution: ProspectResolution.skip,
                    candidate: null,
                  )),
                  child: const Text('Omitir'),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, (
                  resolution: ProspectResolution.create,
                  candidate: null,
                )),
                child: Text(
                  match.strongProspect != null
                      ? 'Confirmar reutilización'
                      : match.candidates.isEmpty
                      ? 'Crear prospecto'
                      : 'Crear de todas formas',
                ),
              ),
            ],
          ),
        );
    if (!context.mounted ||
        scope != ref.read(sessionScopeProvider) ||
        choice == null) {
      return null;
    }
    try {
      final result = match.strongProspect != null || !match.resolutionRequired
          ? await repository.create(request)
          : (await repository.resolve(
              request,
              choice.resolution,
              candidateId: choice.candidate,
            )).prospect;
      if (!context.mounted || scope != ref.read(sessionScopeProvider)) {
        return null;
      }
      return result;
    } on ApiException catch (e) {
      if (!context.mounted || scope != ref.read(sessionScopeProvider)) {
        return null;
      }
      if (e.kind != ApiErrorKind.conflict) rethrow;
      final retry = await showSessionDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('La información cambió, vuelve a verificar'),
          content: Text('${e.code ?? ''}: ${e.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Volver a verificar'),
            ),
          ],
        ),
      );
      if (retry != true) return null;
    }
  }
  return null;
}
