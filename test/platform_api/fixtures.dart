import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';

const entityId = 'c000000000000000000000001';
const stamp = '2026-10-10T00:00:00Z';
const dates = {'createdAt': stamp, 'updatedAt': stamp};
final tenantJson = {
  'id': entityId,
  'name': 'Demo',
  'slug': 'demo',
  'status': 'ACTIVO',
  ...dates
};
final roleJson = {'id': entityId, 'name': 'OWNER', 'tenantId': entityId};
final userJson = {
  'id': entityId,
  'name': 'Owner',
  'email': 'owner@demo.example',
  'platformRole': null,
  'role': roleJson,
  'tenants': [
    {
      'tenantId': entityId,
      'tenantName': 'Demo',
      'tenantSlug': 'demo',
      'role': roleJson
    }
  ],
  'status': 'ACTIVO',
  ...dates
};
final authJson = {
  'accessToken': 'token',
  'user': {
    'id': entityId,
    'name': 'Owner',
    'email': 'owner@demo.example',
    'platformRole': null,
    'status': 'ACTIVO',
    ...dates
  },
  'tenants': [tenantJson],
  'currentTenantId': entityId
};
final campaignJson = {
  'id': entityId,
  'name': 'Campaign',
  'description': null,
  'status': 'ACTIVA',
  'createdBy': entityId,
  ...dates
};
final businessJson = {
  'name': 'Business',
  'category': null,
  'address': null,
  'phone': null,
  'email': null,
  'website': null,
  'source': 'google_maps',
  'sourceIdentifier': null,
  'language': null,
  'metadata': null
};
final prospectJson = {
  'id': entityId,
  'campaignId': entityId,
  ...businessJson,
  'status': 'ACTIVO',
  ...dates
};
final queryJson = {
  'keyword': 'coffee',
  'location': 'Tijuana',
  'source': 'google_maps',
  'limit': 10
};
final jobJson = {
  'id': entityId,
  'campaignId': entityId,
  'status': 'COMPLETED',
  'createdAt': stamp,
  'startedAt': null,
  'completedAt': stamp
};
final detailJson = {
  ...jobJson,
  'tenantId': entityId,
  'requestedBy': entityId,
  'query': queryJson,
  'requestedLimit': 10,
  'error': null,
  'updatedAt': stamp,
  'resultsAvailable': false,
  'results': null,
  'progress': null
};
Map<String, dynamic> envelope(Object data) => {'success': true, 'data': data};
Map<String, dynamic> page(Object item) => {
      'success': true,
      'data': [item],
      'meta': {'page': 2, 'limit': 5, 'total': 6, 'totalPages': 2}
    };
Map<String, dynamic> apiError(int status) => {
      'success': false,
      'error': {
        'code': 'HTTP_$status',
        'message': 'Rejected',
        'details': {
          'reason':
              status == 503 ? 'PROSPECTOR_INTEGRATION_PENDING' : 'rejected'
        },
        'timestamp': stamp
      }
    };

class TestTokenStorage extends SecureTokenStorage {
  TestTokenStorage({this.token = 'token'})
      : super(const FlutterSecureStorage());
  String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String value) async => token = value;
  @override
  Future<void> clearToken() async => token = null;
}

class ContractAdapter implements HttpClientAdapter {
  Object response = envelope({});
  int status = 200;
  RequestOptions? request;
  bool binary = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
        binary && status == 200 ? 'name\nBusiness' : jsonEncode(response),
        status,
        headers: {
          'content-type': [
            binary && status == 200 ? 'text/csv' : 'application/json'
          ],
          'content-disposition': ['attachment; filename="results.csv"']
        });
  }

  @override
  void close({bool force = false}) {}
}
