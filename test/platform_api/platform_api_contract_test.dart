import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import 'fixtures.dart';

const query = PaginationQuery(
    page: 2,
    limit: 5,
    search: 'coffee',
    sortBy: SortField.createdAt,
    sortOrder: SortOrder.desc);
const jobQuery = PaginationQuery(
    page: 2, limit: 5, sortBy: SortField.createdAt, sortOrder: SortOrder.desc);
const prospectingQuery = ProspectingQuery(
    keyword: 'coffee',
    location: 'Tijuana',
    source: ProspectSource.google_maps,
    limit: 10);

class Operation {
  const Operation(this.name, this.method, this.path, this.response, this.call,
      {this.body, this.query = const {}, this.schema, this.header});
  final String name, method, path;
  final Object response;
  final Future<Object?> Function(PlatformApi) call;
  final Map<String, dynamic>? body;
  final Map<String, dynamic> query;
  final String? schema, header;
}

void main() {
  final contract =
      loadYaml(File('Docs/Contracts/platform-api.v1.yaml').readAsStringSync())
          as YamlMap;
  dynamic resolve(dynamic node) {
    if (node is Map && node.containsKey(r'$ref')) {
      dynamic result = contract;
      for (final part in (node[r'$ref'] as String).substring(2).split('/')) {
        result = result[part];
      }
      return result;
    }
    return node;
  }

  void validate(dynamic schema, dynamic value) {
    schema = resolve(schema);
    if (value == null && schema['nullable'] == true) return;
    if (schema['allOf'] != null) {
      for (final part in schema['allOf']) {
        validate(part, value);
      }
    }
    if (schema['enum'] != null) expect(schema['enum'], contains(value));
    switch (schema['type']) {
      case 'object':
        expect(value, isA<Map>());
        for (final key in schema['required'] ?? []) {
          expect(value.containsKey(key), isTrue, reason: 'Missing $key');
        }
        for (final key in (schema['properties'] as Map? ?? {}).keys) {
          if (value.containsKey(key)) {
            validate(schema['properties'][key], value[key]);
          }
        }
      case 'array':
        expect(value, isA<List>());
        for (final item in value) {
          validate(schema['items'], item);
        }
      case 'string':
        expect(value, isA<String>());
      case 'integer':
        expect(value, isA<int>());
      case 'number':
        expect(value, isA<num>());
      case 'boolean':
        expect(value, isA<bool>());
    }
  }

  final operations = <Operation>[
    Operation('health', 'GET', '/api/v1/health', envelope({'status': 'ok'}),
        (api) => api.health.health()),
    Operation('liveness', 'GET', '/api/v1/health/live',
        envelope({'status': 'ok'}), (api) => api.health.live()),
    Operation(
        'readiness',
        'GET',
        '/api/v1/health/ready',
        envelope({'status': 'ok', 'database': 'up'}),
        (api) => api.health.ready()),
    Operation(
        'login',
        'POST',
        '/api/v1/auth/login',
        envelope(authJson),
        (api) => api.auth.login(const LoginRequest(
            email: 'owner@demo.example', password: 'password')),
        body: {'email': 'owner@demo.example', 'password': 'password'},
        schema: 'LoginRequest'),
    Operation('me', 'GET', '/api/v1/auth/me', envelope(authJson),
        (api) => api.auth.me()),
    Operation(
        'select tenant',
        'POST',
        '/api/v1/auth/select-tenant',
        envelope(authJson),
        (api) => api.auth
            .selectTenant(const SelectTenantRequest(tenantId: entityId)),
        body: {'tenantId': entityId},
        schema: 'SelectTenantRequest'),
    Operation('logout', 'POST', '/api/v1/auth/logout', envelope({}),
        (api) async {
      await api.auth.logout();
      return null;
    }),
    Operation('tenants list', 'GET', '/api/v1/tenants', envelope([tenantJson]),
        (api) => api.tenants.list()),
    Operation('tenants get', 'GET', '/api/v1/tenants/$entityId',
        envelope(tenantJson), (api) => api.tenants.get(entityId)),
    Operation(
        'tenants create',
        'POST',
        '/api/v1/tenants',
        envelope(tenantJson),
        (api) => api.tenants
            .create(const CreateTenantRequest(name: 'Demo', slug: 'demo')),
        body: {'name': 'Demo', 'slug': 'demo'},
        schema: 'CreateTenantRequest'),
    Operation('users list', 'GET', '/api/v1/users', page(userJson),
        (api) => api.users.list(query: query),
        query: {
          'page': 2,
          'limit': 5,
          'search': 'coffee',
          'sortBy': 'createdAt',
          'sortOrder': 'desc'
        }),
    Operation('users get', 'GET', '/api/v1/users/$entityId', envelope(userJson),
        (api) => api.users.get(entityId)),
    Operation(
        'users create',
        'POST',
        '/api/v1/users',
        envelope(userJson),
        (api) => api.users.create(const CreateUserRequest(
            name: 'Owner',
            email: 'owner@demo.example',
            password: 'password',
            roleId: entityId)),
        body: {
          'name': 'Owner',
          'email': 'owner@demo.example',
          'password': 'password',
          'roleId': entityId
        },
        schema: 'CreateUserRequest'),
    Operation(
        'users update',
        'PATCH',
        '/api/v1/users/$entityId',
        envelope(userJson),
        (api) => api.users.update(
            entityId,
            const UpdateUserRequest(
                name: 'Updated', status: UserStatus.INACTIVO)),
        body: {'name': 'Updated', 'status': 'INACTIVO'},
        schema: 'UpdateUserRequest'),
    Operation('campaigns list', 'GET', '/api/v1/campaigns', page(campaignJson),
        (api) => api.campaigns.list(query: query),
        query: {
          'page': 2,
          'limit': 5,
          'search': 'coffee',
          'sortBy': 'createdAt',
          'sortOrder': 'desc'
        }),
    Operation('campaigns get', 'GET', '/api/v1/campaigns/$entityId',
        envelope(campaignJson), (api) => api.campaigns.get(entityId)),
    Operation(
        'campaigns create',
        'POST',
        '/api/v1/campaigns',
        envelope(campaignJson),
        (api) => api.campaigns.create(const CreateCampaignRequest(
            name: 'Campaign', description: 'description')),
        body: {'name': 'Campaign', 'description': 'description'},
        schema: 'CreateCampaignRequest'),
    Operation(
        'campaigns update',
        'PATCH',
        '/api/v1/campaigns/$entityId',
        envelope(campaignJson),
        (api) => api.campaigns.update(
            entityId,
            const UpdateCampaignRequest(
                name: 'Updated',
                description: FieldUpdate.set(null),
                status: CampaignStatus.PAUSADA)),
        body: {'name': 'Updated', 'description': null, 'status': 'PAUSADA'},
        schema: 'UpdateCampaignRequest'),
    Operation('prospects list', 'GET', '/api/v1/prospects', page(prospectJson),
        (api) => api.prospects.list(query: query),
        query: {
          'page': 2,
          'limit': 5,
          'search': 'coffee',
          'sortBy': 'createdAt',
          'sortOrder': 'desc'
        }),
    Operation('prospects get', 'GET', '/api/v1/prospects/$entityId',
        envelope(prospectJson), (api) => api.prospects.get(entityId)),
    Operation(
        'prospects update',
        'PATCH',
        '/api/v1/prospects/$entityId',
        envelope(prospectJson),
        (api) => api.prospects.update(
            entityId,
            const UpdateProspectRequest(
                name: 'Updated',
                phone: FieldUpdate.set(null),
                metadata: FieldUpdate.set({'note': 'x'}),
                status: ProspectStatus.INACTIVO)),
        body: {
          'name': 'Updated',
          'phone': null,
          'metadata': {'note': 'x'},
          'status': 'INACTIVO'
        },
        schema: 'UpdateProspectRequest'),
    Operation(
        'users deactivate', 'DELETE', '/api/v1/users/$entityId', envelope({}),
        (api) async {
      await api.users.deactivate(entityId);
      return null;
    }),
    Operation('campaigns archive', 'DELETE', '/api/v1/campaigns/$entityId',
        envelope({}), (api) async {
      await api.campaigns.archive(entityId);
      return null;
    }),
    Operation('campaigns permanent delete', 'DELETE',
        '/api/v1/campaigns/$entityId', envelope({}), (api) async {
      await api.campaigns.deletePermanently(entityId);
      return null;
    }, query: {'permanent': true}),
    Operation(
        'campaign prospects',
        'GET',
        '/api/v1/campaigns/$entityId/prospects',
        page(prospectJson),
        (api) => api.campaigns.prospects(entityId, query: query),
        query: {
          'page': 2,
          'limit': 5,
          'search': 'coffee',
          'sortBy': 'createdAt',
          'sortOrder': 'desc'
        }),
    Operation(
        'prospects for campaign',
        'GET',
        '/api/v1/campaigns/$entityId/prospects',
        page(prospectJson),
        (api) => api.prospects.forCampaign(entityId, query: query),
        query: {
          'page': 2,
          'limit': 5,
          'search': 'coffee',
          'sortBy': 'createdAt',
          'sortOrder': 'desc'
        }),
    Operation('jobs list', 'GET', '/api/v1/prospecting-jobs', page(jobJson),
        (api) => api.prospectingJobs.list(query: jobQuery), query: {
      'page': 2,
      'limit': 5,
      'sortBy': 'createdAt',
      'sortOrder': 'desc'
    }),
    Operation('jobs detail', 'GET', '/api/v1/prospecting-jobs/$entityId',
        envelope(detailJson), (api) => api.prospectingJobs.get(entityId)),
    Operation(
        'jobs create contract only',
        'POST',
        '/api/v1/prospecting-jobs',
        envelope(detailJson),
        (api) => api.prospectingJobs.create(
            const CreateProspectingJobRequest(
                campaignId: entityId, query: prospectingQuery),
            idempotencyKey: 'test-key'),
        body: {'campaignId': entityId, 'query': queryJson},
        schema: 'CreateProspectingJobRequest',
        header: 'test-key'),
    Operation(
        'jobs cancel contract only',
        'POST',
        '/api/v1/prospecting-jobs/$entityId/cancel',
        envelope(detailJson),
        (api) => api.prospectingJobs.cancel(entityId)),
    Operation(
        'jobs persist contract only',
        'POST',
        '/api/v1/prospecting-jobs/$entityId/persist',
        envelope({'persisted': 1, 'skipped': 0}),
        (api) => api.prospectingJobs.persist(entityId)),
    Operation(
        'jobs export contract only',
        'GET',
        '/api/v1/prospecting-jobs/$entityId/export',
        envelope({}),
        (api) => api.prospectingJobs.export(entityId, format: ExportFormat.csv),
        query: {'format': 'csv'}),
  ];
  PlatformApi client(ContractAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    return PlatformApi(ApiClient(
        config: const AppConfig(apiBaseUrl: 'http://localhost'),
        storage: TestTokenStorage(),
        dio: dio));
  }

  for (final op in operations) {
    test('contract: ${op.name}', () async {
      final adapter = ContractAdapter()
        ..response = op.response
        ..binary = op.name.startsWith('jobs export');
      final result = await op.call(client(adapter));
      final request = adapter.request!;
      expect(request.method, op.method);
      expect(request.path, op.path);
      expect(request.queryParameters, op.query);
      expect(request.data, op.body);
      expect(request.headers['Authorization'], 'Bearer token');
      if (op.header != null) {
        expect(request.headers['Idempotency-Key'], op.header);
      }
      final template = op.path.replaceAll(entityId, '{id}');
      final path = contract['paths'][template];
      expect(path, isNotNull);
      final definition = path[op.method.toLowerCase()];
      expect(definition, isNotNull);
      final parameters = [...?path['parameters'], ...?definition['parameters']]
          .map(resolve)
          .toList();
      final queryNames =
          parameters.where((p) => p['in'] == 'query').map((p) => p['name']);
      expect(queryNames, containsAll(op.query.keys));
      if (op.schema != null) {
        final requestSchema =
            definition['requestBody']['content']['application/json']['schema'];
        expect(requestSchema[r'$ref'], '#/components/schemas/${op.schema}');
        validate(requestSchema, op.body);
        expect((resolve(requestSchema)['properties'] as Map).keys,
            containsAll(op.body!.keys));
      } else {
        expect(definition['requestBody'], isNull);
      }
      if (!adapter.binary) {
        final response =
            resolve(definition['responses'][op.name.endsWith('create')
                ? '201'
                : op.name == 'jobs create contract only'
                    ? '201'
                    : '200']);
        validate(
            response['content']['application/json']['schema'], op.response);
      }
      if (result is PaginatedResult) {
        expect(result.meta.page, 2);
        expect(result.items, hasLength(1));
      }
      if (result is Health) expect(result.status, HealthStatus.ok);
      if (result is Campaign) expect(result.createdBy, entityId);
      if (result is User) expect(result.role!.name, RoleName.OWNER);
      if (result is Prospect) expect(result.source, ProspectSource.google_maps);
      if (result is ProspectingJobDetail) {
        expect(result.status, ProspectingJobStatus.COMPLETED);
        expect(result.resultsAvailable, isFalse);
      }
      if (result is ApiDownload) {
        expect(result.bytes, isNotEmpty);
        expect(result.contentType, 'text/csv');
      }
    });
  }
  test('contract: every public endpoint is represented', () {
    final exercised = operations
        .map((op) =>
            '${op.method.toLowerCase()} ${op.path.replaceAll(entityId, '{id}')}')
        .toSet();
    final declared = <String>{};
    for (final path in (contract['paths'] as Map).keys) {
      for (final method in ['get', 'post', 'patch', 'delete']) {
        if (contract['paths'][path][method] != null) {
          declared.add('$method $path');
        }
      }
    }
    expect(exercised, declared);
  });
  for (final op in operations.where((op) => [
        'readiness',
        'tenants create',
        'users create',
        'campaigns update',
        'prospects update',
        'jobs create contract only',
        'jobs cancel contract only',
        'jobs persist contract only',
        'jobs export contract only'
      ].contains(op.name))) {
    for (final status in op.name.startsWith('jobs') || op.name == 'readiness'
        ? [503]
        : [400, 401, 403, 404, 409]) {
      test('${op.name}: HTTP $status propagates code/details', () async {
        final adapter = ContractAdapter()
          ..status = status
          ..response = apiError(status)
          ..binary = op.name.startsWith('jobs export');
        await expectLater(
            op.call(client(adapter)),
            throwsA(isA<ApiException>()
                .having((e) => e.statusCode, 'status', status)
                .having((e) => e.code, 'code', 'HTTP_$status')
                .having(
                    (e) => e.details,
                    'details',
                    apiError(status)['error'] is Map
                        ? (apiError(status)['error'] as Map)['details']
                        : null)));
      });
    }
  }
  test('DTO nullable PATCH fields preserve omission versus explicit null', () {
    expect(const UpdateCampaignRequest(name: 'x').toJson(), {'name': 'x'});
    expect(
        const UpdateCampaignRequest(description: FieldUpdate.set(null))
            .toJson(),
        {'description': null});
    expect(const UpdateUserRequest().toJson, throwsArgumentError);
    expect(const UpdateProspectRequest().toJson, throwsArgumentError);
  });
  test('invalid DTOs and query types fail visibly', () {
    expect(() => Campaign.fromJson({...campaignJson, 'status': 'invented'}),
        throwsFormatException);
    expect(
        () => ProspectingJobDetail.fromJson({...detailJson}..remove('results')),
        throwsFormatException);
    expect(() => Tenant.fromJson({...tenantJson, 'createdAt': 42}),
        throwsFormatException);
    expect(() => const PaginationQuery(page: 0).toQuery(), throwsArgumentError);
    expect(
        () => const PaginationQuery(limit: 101).toQuery(), throwsArgumentError);
    final adapter = ContractAdapter();
    expect(client(adapter).prospectingJobs.list(query: query),
        throwsArgumentError);
  });
  test('nested Jobs DTOs parse cache data without claiming availability', () {
    final detail = ProspectingJobDetail.fromJson({
      ...detailJson,
      'resultsAvailable': true,
      'results': [businessJson],
      'progress': {
        'source': 'google_maps',
        'stage': 'done',
        'message': 'Done',
        'percentage': 100
      }
    });
    expect(detail.results!.single.source, ProspectSource.google_maps);
    expect(detail.progress!.percentage, 100);
    expect(User.fromJson({...userJson, 'role': null}).role, isNull);
  });
  test('invalid success wrappers propagate parsing errors', () async {
    final adapter = ContractAdapter()
      ..response = {'success': false, 'data': tenantJson};
    await expectLater(
        client(adapter).tenants.get(entityId), throwsFormatException);
    adapter.response = envelope({});
    await expectLater(client(adapter).campaigns.list(), throwsFormatException);
    adapter.response = envelope({'unexpected': true});
    await expectLater(
        client(adapter).users.deactivate(entityId), throwsFormatException);
    adapter.response = envelope({...authJson}..remove('currentTenantId'));
    await expectLater(client(adapter).auth.me(), throwsFormatException);
  });
}
