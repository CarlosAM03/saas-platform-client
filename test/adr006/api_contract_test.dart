import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:yaml/yaml.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/platform_api/platform_api.dart';
import '../foundation_network_test.dart' show MemoryStorage;
import '../platform_api/fixtures.dart'
    show ContractAdapter, envelope, tenantJson, entityId;
import 'fixtures.dart';
import '../foundation_auth_test.dart' as auth_fixture;

class CountingStorage extends MemoryStorage {
  CountingStorage() : super(token: 'synthetic-normal-session');
  int reads = 0, clears = 0;
  @override
  Future<String?> readToken() async {
    reads++;
    return super.readToken();
  }

  @override
  Future<void> clearToken() async {
    clears++;
    await super.clearToken();
  }
}

class CaptureOutput extends LogOutput {
  final lines = <String>[];
  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  final approved =
      loadYaml(
            File(
              'Docs/Contracts/platform-api.tenant-registration.approved.yaml',
            ).readAsStringSync(),
          )
          as YamlMap;
  late ContractAdapter adapter;
  late CountingStorage storage;
  late ApiClient client;
  late PlatformApi api;
  late CaptureOutput output;
  var unauthorized = 0;
  setUp(() {
    adapter = ContractAdapter();
    storage = CountingStorage();
    output = CaptureOutput();
    unauthorized = 0;
    client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'http://localhost'),
      storage: storage,
      dio: Dio(
        BaseOptions(
          baseUrl: 'http://localhost',
          headers: {'authorization': 'inherited-synthetic-header'},
        ),
      )..httpClientAdapter = adapter,
      logger: Logger(output: output),
      onUnauthorized: () async {
        unauthorized++;
      },
    );
    api = PlatformApi(client);
  });
  const request = RegisterTenantRequest(
    tenantName: ' Company ',
    tenantSlug: 'company',
    ownerName: ' Owner ',
    ownerEmail: ' OWNER@EXAMPLE.INVALID ',
  );
  test(
    'registration: exact approved payload and 201 tenant/onboarding even with failed delivery',
    () async {
      adapter.status = 201;
      for (final status in DeliveryStatus.values) {
        adapter.response = envelope({
          'tenant': tenantJson,
          'onboarding': onboardingJson(delivery: status.name),
        });
        final result = await api.tenantRegistration.register(request);
        expect(result.onboarding.deliveryStatus, status);
        expect(adapter.request!.path, '/api/v1/tenants/register');
        expect(adapter.request!.method, 'POST');
        expect(adapter.request!.data, {
          'tenantName': 'Company',
          'tenantSlug': 'company',
          'ownerName': 'Owner',
          'ownerEmail': 'owner@example.invalid',
        });
        expect(adapter.request!.headers['Authorization'] != null, isTrue);
      }
      final operation = approved['paths']['/api/v1/tenants/register']['post'];
      final schema = approved['components']['schemas']['RegisterTenantRequest'];
      expect(
        (schema['properties'] as Map).keys.toSet(),
        request.toJson().keys.toSet(),
      );
      expect(operation['responses']['201'], isNotNull);
      expect(
        operation['requestBody']['content']['application/json']['schema'][r'$ref'],
        '#/components/schemas/RegisterTenantRequest',
      );
    },
  );
  test('onboarding GET parses all fields and resend POST has no body', () async {
    adapter.response = envelope(onboardingJson());
    final result = await api.tenantRegistration.onboarding(entityId);
    expect(adapter.request!.path, '/api/v1/tenants/$entityId/onboarding');
    expect(adapter.request!.method, 'GET');
    expect(result.activationStatus, ActivationStatus.PENDING_FIRST_ACCESS);
    expect(result.lastAttemptAt, isNotNull);
    expect(result.activationLinkExpiresAt, isNotNull);
    expect(result.completedAt, isNull);
    expect(result.providerAcceptedAt, isNull);
    await api.tenantRegistration.resend(entityId);
    expect(adapter.request!.path, '/api/v1/tenants/$entityId/resend-welcome');
    expect(adapter.request!.method, 'POST');
    expect(adapter.request!.data, isNull);
    expect(
      approved['paths']['/api/v1/tenants/{id}/resend-welcome']['post']['requestBody'],
      isNull,
    );
    expect(
      approved['paths']['/api/v1/tenants/{id}/onboarding']['get']['responses']['200'],
      isNotNull,
    );
  });
  test(
    'redeem/complete serialize body-only credentials without reading or attaching saved JWT',
    () async {
      adapter.response = envelope({
        'action': 'CHANGE_PASSWORD_REQUIRED',
        'firstAccessToken': challengeCode(),
        'expiresAt': '2030-01-01T00:00:00Z',
      });
      final result = await api.tenantRegistration.redeem(
        RedeemFirstAccessRequest(activationCode()),
      );
      expect(result.firstAccessToken == challengeCode(), isTrue);
      expect(adapter.request!.path, '/api/v1/auth/redeem-first-access');
      expect((adapter.request!.data as Map).keys.toList(), ['activationToken']);
      expect(
        (adapter.request!.data as Map)['activationToken'] == activationCode(),
        isTrue,
      );
      expect(
        adapter.request!.headers.keys.any(
          (k) => k.toLowerCase() == 'authorization',
        ),
        isFalse,
      );
      adapter.response = envelope({'action': 'LOGIN_REQUIRED'});
      await api.tenantRegistration.complete(
        CompleteFirstAccessRequest(
          firstAccessToken: challengeCode(),
          newPassword: passwordValue(),
        ),
      );
      expect(adapter.request!.path, '/api/v1/auth/complete-first-access');
      expect((adapter.request!.data as Map).keys.toSet(), {
        'firstAccessToken',
        'newPassword',
      });
      expect(
        (adapter.request!.data as Map)['firstAccessToken'] == challengeCode(),
        isTrue,
      );
      expect(
        (adapter.request!.data as Map)['newPassword'] == passwordValue(),
        isTrue,
      );
      expect(
        adapter.request!.headers.keys.any(
          (k) => k.toLowerCase() == 'authorization',
        ),
        isFalse,
      );
      expect(storage.reads, 0);
      expect(storage.clears, 0);
      expect(unauthorized, 0);
      for (final path in [
        '/api/v1/auth/redeem-first-access',
        '/api/v1/auth/complete-first-access',
      ]) {
        expect(approved['paths'][path]['post']['security'], isEmpty);
      }
    },
  );
  for (final status in [400, 401, 403, 409, 429, 503, 500]) {
    test(
      'public activation HTTP $status is sanitized and never logs out existing session',
      () async {
        adapter.status = status;
        adapter.response = {
          'success': false,
          'error': {
            'message': activationCode(),
            'details': {'unsafe': passwordValue()},
            'code': challengeCode(),
          },
        };
        for (final invoke in <Future<Object?> Function()>[
          () => api.tenantRegistration.redeem(
            RedeemFirstAccessRequest(activationCode()),
          ),
          () => api.tenantRegistration.complete(
            CompleteFirstAccessRequest(
              firstAccessToken: challengeCode(),
              newPassword: passwordValue(),
            ),
          ),
        ]) {
          await expectLater(
            invoke(),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.statusCode, 'status', status)
                  .having((e) => e.details, 'details', isNull)
                  .having(
                    (e) => e.message.contains(activationCode()),
                    'safe',
                    false,
                  ),
            ),
          );
        }
        expect(storage.reads, 0);
        expect(storage.clears, 0);
        expect(unauthorized, 0);
        expect(storage.token != null, isTrue);
        expect(output.lines, isEmpty);
      },
    );
  }
  test('public bypass cannot be used for other API operations', () async {
    await expectLater(
      client.postPublicActivation('/api/v1/users', data: {}),
      throwsArgumentError,
    );
    expect(adapter.request, isNull);
  });
  test(
    'activation 401 preserves the actual restored AuthController state',
    () async {
      final sessionStorage = auth_fixture.MemoryTokenStorage(
        token: 'synthetic-session',
      );
      final repository = auth_fixture.StubAuthRepository(sessionStorage)
        ..result = auth_fixture.contextFor(tenantId: 'tenant');
      final c = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(sessionStorage),
          authRepositoryProvider.overrideWithValue(repository),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: const AppConfig(apiBaseUrl: 'http://localhost'),
              storage: sessionStorage,
              dio: Dio(BaseOptions(baseUrl: 'http://localhost'))
                ..httpClientAdapter = adapter,
              onUnauthorized: () async {
                ref.read(authControllerProvider.notifier).sessionExpired();
              },
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.read(authControllerProvider);
      await auth_fixture.settleRestore();
      final previous = c.read(authControllerProvider);
      adapter.status = 401;
      adapter.response = {
        'success': false,
        'error': {'message': 'Invalid credentials'},
      };
      await expectLater(
        c
            .read(platformApiProvider)
            .tenantRegistration
            .redeem(RedeemFirstAccessRequest(activationCode())),
        throwsA(isA<ApiException>()),
      );
      expect(identical(c.read(authControllerProvider), previous), isTrue);
      expect(sessionStorage.token != null, isTrue);
    },
  );
  test(
    'secret DTO diagnostics and invalid action errors cannot reflect credentials',
    () {
      for (final dto in [
        RedeemFirstAccessRequest(activationCode()),
        CompleteFirstAccessRequest(
          firstAccessToken: challengeCode(),
          newPassword: passwordValue(),
        ),
        FirstAccessRequired(
          firstAccessToken: challengeCode(),
          expiresAt: DateTime.utc(2030),
        ),
      ]) {
        expect(dto.toString().contains(activationCode()), isFalse);
        expect(dto.toString().contains(challengeCode()), isFalse);
        expect(dto.toString().contains(passwordValue()), isFalse);
      }
      expect(
        () => FirstAccessRequired.fromJson({'action': activationCode()}),
        throwsFormatException,
      );
      expect(
        () => FirstAccessCompleted.fromJson({'action': challengeCode()}),
        throwsFormatException,
      );
      expect(
        () => TenantOnboarding.fromJson(
          onboardingJson()..remove('lastAttemptAt'),
        ),
        throwsFormatException,
      );
    },
  );
}
