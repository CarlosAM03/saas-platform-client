import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/errors/error_mapper.dart';
import 'fixtures.dart';

void main() {
  test('persisted sources parse; engine sources stay restricted', () {
    for (final source in PersistedProspectSource.values) {
      expect(Prospect.fromJson({...prospectJson, 'source': source.name}).source,
          source);
    }
    for (final source in ['manual', 'csv']) {
      expect(() => ProspectingQuery.fromJson({...queryJson, 'source': source}),
          throwsFormatException);
      expect(() => BusinessResult.fromJson({...businessJson, 'source': source}),
          throwsFormatException);
      expect(() => PipelineProgress.fromJson({'source': source}),
          throwsFormatException);
    }
  });
  test('upload bytes are copied and immutable', () {
    final original = [65, 66];
    final file = ApiUploadFile(filename: 'a.csv', bytes: original);
    original[0] = 67;
    expect(file.bytes, [65, 66]);
    expect(() => file.bytes[0] = 0, throwsUnsupportedError);
  });
  test('CSV rows, differences and rejected result parse completely', () {
    final preview = ProspectImportPreview.fromJson({
      ...importPreviewJson,
      'rows': [
        {
          'record': 1,
          'classification': 'MATCH',
          'values': {'name': 'Café', 'phone': null},
          'errors': [],
          'matches': [
            {
              'id': entityId,
              'campaignIds': [entityId],
              'sharedWithOtherCampaigns': true,
              'differences': [
                {'field': 'phone', 'existing': '123', 'imported': null}
              ]
            }
          ]
        },
        for (final kind in ['INVALID', 'CONFLICT'])
          {
            'record': 2,
            'classification': kind,
            'values': {'name': ''},
            'errors': [
              {'field': 'name', 'message': 'invalid'}
            ],
            'matches': []
          }
      ]
    });
    expect(preview.rows.first.matches.single.sharedWithOtherCampaigns, isTrue);
    expect(
        preview.rows.first.matches.single.differences.single.imported, isNull);
    expect(preview.rows.first.values.presentFields, contains('phone'));
    expect(preview.rows.last.errors.single.field, 'name');
    final result = ProspectImportResult.fromJson({
      ...importResultJson,
      'rows': [
        {
          'record': 1,
          'action': 'REJECTED',
          'errors': [
            {'field': 'name', 'message': 'invalid'}
          ]
        }
      ]
    });
    expect(result.rows.single.action, ProspectImportResultAction.REJECTED);
    expect(result.rows.single.prospectId, isNull);
    for (final action in ProspectImportAction.values) {
      expect(ProspectImportDecision(record: 1, action: action).toJson(),
          {'record': 1, 'action': action.name});
    }
  });
  test(
      'manual create sends only contractual fields and preserves optional null',
      () {
    expect(const CreateProspectRequest(campaignId: 'c', name: 'A').toJson(),
        {'campaignId': 'c', 'name': 'A'});
    expect(
        const CreateProspectRequest(
                campaignId: 'c', name: 'A', email: FieldUpdate.set(null))
            .toJson(),
        {'campaignId': 'c', 'name': 'A', 'email': null});
  });
  test('413 has a specific message', () {
    expect(
        const ErrorMapper().userMessage(const ApiException(
            kind: ApiErrorKind.payloadTooLarge, message: 'large')),
        contains('5 MB'));
  });
}
