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

  test('PaginationMeta applies contract defaults only when fields are absent', () {
    final meta = PaginationMeta.fromJson({'page': 2, 'limit': 10, 'total': 11, 'totalPages': 2});
    expect(meta.page, 2);
    expect(meta.totalPages, 2);
  });
}
