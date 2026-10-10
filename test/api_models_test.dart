import 'package:flutter_test/flutter_test.dart';

import 'package:saas_platform_client/shared/models/api_models.dart';

void main() {
  test('AuthContext preserves nullable tenant and separates AuthUser', () {
    final context = AuthContext.fromJson({
      'accessToken': 'test-token',
      'user': {
        'id': 'c12345678901234567890',
        'name': 'Admin',
        'email': 'admin@example.com',
        'platformRole': 'ADMIN',
        'status': 'ACTIVO',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      },
      'tenants': [],
      'currentTenantId': null,
    });

    expect(context.user.platformRole, 'ADMIN');
    expect(context.currentTenantId, isNull);
    expect(context.tenants, isEmpty);
  });

  test('PaginationMeta enforces contract fields and ranges', () {
    final meta = PaginationMeta.fromJson(
        {'page': 2, 'limit': 10, 'total': 11, 'totalPages': 2});
    expect(meta.page, 2);
    expect(meta.totalPages, 2);
    expect(() => PaginationMeta.fromJson({'page': 1, 'limit': 20, 'total': 0}),
        throwsFormatException);
    expect(
        () => PaginationMeta.fromJson(
            {'page': 1.5, 'limit': 20, 'total': 0, 'totalPages': 0}),
        throwsFormatException);
    expect(
        () => PaginationMeta.fromJson(
            {'page': 1, 'limit': 101, 'total': 0, 'totalPages': 0}),
        throwsFormatException);
  });

  test('unwrapObject accepts a contractual object', () {
    expect(
        unwrapObject({
          'success': true,
          'data': {'id': 'one'}
        }),
        {'id': 'one'});
  });

  test('unwrapList converts object items', () {
    final result = unwrapList({
      'success': true,
      'data': [
        {'id': 'one'}
      ]
    }, (json) => json['id'] as String);
    expect(result, ['one']);
  });

  test('unwrapPaginated returns items and strict metadata', () {
    final result = unwrapPaginated(
      {
        'success': true,
        'data': [
          {'id': 'one'}
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1}
      },
      (json) => json['id'] as String,
    );
    expect(result.items, ['one']);
    expect(result.meta.total, 1);
  });

  test('invalid response envelopes and types fail visibly', () {
    expect(() => unwrapObject({'success': false, 'data': {}}),
        throwsFormatException);
    expect(() => unwrapObject({'success': true}), throwsFormatException);
    expect(() => unwrapObject({'success': true, 'data': []}),
        throwsFormatException);
    expect(() => unwrapList({'success': true, 'data': {}}, (json) => json),
        throwsFormatException);
    expect(
        () => unwrapList({
              'success': true,
              'data': [1]
            }, (json) => json),
        throwsFormatException);
    expect(() => unwrapPaginated({'success': true, 'data': []}, (json) => json),
        throwsFormatException);
    expect(
        () => unwrapPaginated({
              'success': true,
              'data': [],
              'meta': {'page': '1'}
            }, (json) => json),
        throwsFormatException);
  });
}
