import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../foundation_network_test.dart' show MemoryStorage;
import '../platform_api/fixtures.dart';

void main() {
  test(
    'QF-01: nullable global role is independent of tenant OWNER/MEMBER',
    () async {
      final adapter = ContractAdapter();
      final api = PlatformApi(
        ApiClient(
          config: const AppConfig(apiBaseUrl: 'http://localhost'),
          storage: MemoryStorage(),
          dio: Dio(BaseOptions(baseUrl: 'http://localhost'))
            ..httpClientAdapter = adapter,
        ),
      );
      final rows = [
        for (final name in ['OWNER', 'MEMBER'])
          {
            ...userJson,
            'platformRole': null,
            'role': {...roleJson, 'name': name},
          },
        {...userJson, 'platformRole': 'ADMIN', 'role': null, 'tenants': []},
        {
          ...userJson,
          'tenants': [
            ...(userJson['tenants'] as List),
            {
              'tenantId': 'tenant-b',
              'tenantName': 'Synthetic B',
              'tenantSlug': 'synthetic-b',
              'role': {
                ...roleJson,
                'name': 'MEMBER',
                'tenantId': 'tenant-b',
                'description': null,
              },
            },
          ],
        },
      ];
      adapter.response = {
        'success': true,
        'data': rows,
        'meta': {'page': 2, 'limit': 4, 'total': 8, 'totalPages': 2},
      };
      final page = await api.users.list(
        query: const PaginationQuery(page: 2, limit: 4, search: 'synthetic'),
      );
      expect(page.items.length, 4);
      expect(page.items[0].platformRole, isNull);
      expect(page.items[0].role!.name, RoleName.OWNER);
      expect(page.items[1].role!.name, RoleName.MEMBER);
      expect(page.items[2].platformRole, PlatformRole.ADMIN);
      expect(page.items[2].role, isNull);
      expect(page.items[3].tenants.length, 2);
      expect(adapter.request!.queryParameters['page'], 2);
      expect(adapter.request!.queryParameters['search'], 'synthetic');
    },
  );
}
