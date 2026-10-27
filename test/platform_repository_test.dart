import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/features/workspace/data/platform_repository.dart';
import 'foundation_auth_test.dart' show MemoryTokenStorage;

class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object response = {'success': true, 'data': <Object>[]};
  int statusCode = 200;
  Future<void> Function()? beforeReply;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    await beforeReply?.call();
    return ResponseBody.fromString(jsonEncode(response), statusCode, headers: {
      'content-type': ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late RecordingAdapter adapter;
  late PlatformRepository repository;
  setUp(() {
    adapter = RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    repository = PlatformRepository(ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
        storage: MemoryTokenStorage(token: 'jwt'),
        dio: dio));
  });
  test(
      'unwraps paginated collections and sends search/page without a tenant override',
      () async {
    adapter.response = {
      'success': true,
      'data': [
        {'id': 'c1', 'name': 'Verano'}
      ],
      'meta': {'page': 2, 'limit': 20, 'total': 21, 'totalPages': 2}
    };
    final page =
        await repository.list('campaigns', (page: 2, search: 'Verano'));
    expect(page.meta.total, 21);
    expect(page.items.single['id'], 'c1');
    expect(adapter.requests.single.queryParameters, {
      'page': 2,
      'limit': 20,
      'search': 'Verano',
      'sortBy': 'createdAt',
      'sortOrder': 'desc'
    });
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt');
  });
  test('tenant discovery reads an array rather than a paginated object',
      () async {
    adapter.response = {
      'success': true,
      'data': [
        {'id': 't1', 'name': 'ACME', 'slug': 'acme', 'status': 'ACTIVO'}
      ]
    };
    expect((await repository.organizations()).single['id'], 't1');
    expect(adapter.requests.single.path, '/api/v1/tenants');
  });
  test('patch preserves explicit null when clearing a prospect contact',
      () async {
    adapter.response = {
      'success': true,
      'data': {'id': 'p1', 'email': null}
    };
    await repository.update('prospects', 'p1', {'email': null});
    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.data, {'email': null});
  });
  test('archive and permanent deletion use the backend boolean query contract',
      () async {
    await repository.archiveCampaign('c1');
    await repository.archiveCampaign('c1', permanent: true);
    expect(adapter.requests.map((r) => r.uri.queryParameters['permanent']),
        ['false', 'true']);
    expect(adapter.requests.every((r) => r.method == 'DELETE'), isTrue);
  });
  test('late 401 from a prior organization does not delete the new token',
      () async {
    final storage = MemoryTokenStorage(token: 'old-tenant-token');
    var expired = false;
    adapter.statusCode = 401;
    adapter.response = {
      'success': false,
      'error': {'message': 'Expired'}
    };
    adapter.beforeReply = () => storage.writeToken('new-tenant-token');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
        storage: storage,
        dio: dio,
        onUnauthorized: () async {
          expired = true;
        });
    await expectLater(
        client.get('/api/v1/campaigns'), throwsA(isA<ApiException>()));
    expect(storage.token, 'new-tenant-token');
    expect(expired, isFalse);
  });
}
