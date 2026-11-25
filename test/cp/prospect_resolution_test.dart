import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/features/prospects/data/prospect_context_repository.dart';
import 'package:saas_platform_client/features/prospects/presentation/prospect_match_dialog.dart';
import 'package:saas_platform_client/features/prospects/state/prospect_context_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/platform_api/prospect_context_api.dart';
import '../features/feature_fixtures.dart';

class ChangingCandidate implements ProspectContextRepository {
  int matches = 0;
  final resolvedIds = <String?>[];
  @override
  Future<ProspectMatch> match(ProspectIntakeRequest request) async {
    matches++;
    return ProspectMatch.fromJson({
      'strongProspect': null,
      'candidates': [
        {...prospectJson, 'id': 'candidate-$matches'},
      ],
      'resolutionRequired': true,
    });
  }

  @override
  Future<ProspectResolutionResult> resolve(
    ProspectIntakeRequest request,
    ProspectResolution resolution, {
    String? candidateId,
  }) async {
    resolvedIds.add(candidateId);
    if (matches == 1) {
      throw const ApiException(
        kind: ApiErrorKind.conflict,
        statusCode: 409,
        code: 'CONFLICT',
        message: 'Candidate changed',
      );
    }
    return ProspectResolutionResult.fromJson({
      'action': resolution.wire,
      'prospect': prospectJson,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    '409 resolution requires explicit verification and discards the old candidate',
    (tester) async {
      final repo = ChangingCandidate();
      Prospect? created;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(FeatureAuthController.new),
            prospectContextRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async {
                    created = await verifyAndCreateProspect(
                      context,
                      ref,
                      const ProspectIntakeRequest(
                        CreateProspectRequest(
                          campaignId: 'c',
                          name: 'Synthetic',
                        ),
                      ),
                    );
                  },
                  child: const Text('Verificar'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vincular'));
      await tester.pumpAndSettle();
      expect(
        find.text('La información cambió, vuelve a verificar'),
        findsOneWidget,
      );
      expect(repo.matches, 1);
      expect(repo.resolvedIds, ['candidate-1']);
      await tester.tap(find.text('Volver a verificar'));
      await tester.pumpAndSettle();
      expect(repo.matches, 2);
      expect(repo.resolvedIds, ['candidate-1']);
      await tester.tap(find.text('Vincular'));
      await tester.pumpAndSettle();
      expect(repo.resolvedIds, ['candidate-1', 'candidate-2']);
      expect(created!.id, entityId);
    },
  );
}
