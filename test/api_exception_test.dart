import 'package:flutter_test/flutter_test.dart';

import 'package:saas_platform_client/core/errors/api_exception.dart';

void main() {
  test('ApiException exposes standard HTTP classification', () {
    const exception = ApiException(kind: ApiErrorKind.forbidden, statusCode: 403, message: 'Forbidden');
    expect(exception.statusCode, 403);
    expect(exception.kind, ApiErrorKind.forbidden);
  });
}
