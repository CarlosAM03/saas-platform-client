import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/storage/secure_token_storage.dart';
import 'package:saas_platform_client/features/auth/data/auth_repository.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/routes/app_router.dart';
import 'package:saas_platform_client/shared/models/api_models.dart';

class MemoryTokenStorage extends SecureTokenStorage {
  MemoryTokenStorage({this.token}) : super(const FlutterSecureStorage());

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> clearToken() async => token = null;
}

class StubAuthRepository extends AuthRepository {
  StubAuthRepository(MemoryTokenStorage storage)
      : super(ApiClient(
            config: const AppConfig(apiBaseUrl: 'http://localhost'),
            storage: storage));

  AuthContext? result;
  Object? error;
  void Function()? beforeError;
  bool logoutCalled = false;

  Future<AuthContext> _answer() async {
    if (error != null) {
      beforeError?.call();
      throw error!;
    }
    return result!;
  }

  @override
  Future<AuthContext> me() => _answer();

  @override
  Future<AuthContext> login(
          {required String email, required String password}) =>
      _answer();

  @override
  Future<AuthContext> selectTenant(String tenantId) => _answer();

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (error != null) throw error!;
  }
}

class StubAdapter implements HttpClientAdapter {
  int statusCode = 200;
  String? bearer;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    bearer = options.headers['Authorization']?.toString();
    return ResponseBody.fromString(
      statusCode == 200
          ? '{"success":true,"data":{}}'
          : '{"success":false,"error":{"message":"Rejected"}}',
      statusCode,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AuthContext contextFor(
        {String? tenantId,
        String? platformRole,
        String token = 'new-token',
        List<AuthTenant>? tenants}) =>
    AuthContext(
      accessToken: token,
      user: AuthUser(
        id: 'user-1',
        name: 'User',
        email: 'user@example.com',
        platformRole: platformRole,
        status: 'ACTIVO',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      tenants: tenants ??
          const [
            AuthTenant(
                id: 'tenant-1',
                name: 'Tenant',
                slug: 'tenant',
                status: 'ACTIVO')
          ],
      currentTenantId: tenantId,
    );

ProviderContainer containerFor(
        MemoryTokenStorage storage, StubAuthRepository repository) =>
    ProviderContainer(overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repository),
    ]);

Future<void> settleRestore() async =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('Auth Foundation', () {
    test('startup without token goes to login', () async {
      final storage = MemoryTokenStorage();
      final container = containerFor(storage, StubAuthRepository(storage));
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);
    });

    test('restores a valid token through auth/me', () async {
      final storage = MemoryTokenStorage(token: 'existing-token');
      final repository = StubAuthRepository(storage)
        ..result = contextFor(tenantId: 'tenant-1');
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      expect(container.read(authControllerProvider).status,
          AuthStatus.authenticated);
      expect(storage.token, 'existing-token');
    });

    test('401 during restore expires session and clears token', () async {
      final storage = MemoryTokenStorage(token: 'expired-token');
      final repository = StubAuthRepository(storage)
        ..error = const ApiException(
            kind: ApiErrorKind.unauthorized,
            statusCode: 401,
            message: 'Expired');
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      expect(container.read(authControllerProvider).status,
          AuthStatus.sessionExpired);
      expect(storage.token, isNull);
    });

    test('backend unavailable preserves token for a later restore', () async {
      final storage = MemoryTokenStorage(token: 'existing-token');
      final repository = StubAuthRepository(storage)
        ..error =
            const ApiException(kind: ApiErrorKind.network, message: 'Offline');
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      expect(container.read(authControllerProvider).status,
          AuthStatus.backendUnavailable);
      expect(storage.token, 'existing-token');
    });

    test('login stores token and failure remains unauthenticated', () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)..result = contextFor();
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      expect(container.read(authControllerProvider).status,
          AuthStatus.authenticated);
      expect(storage.token, 'new-token');
      repository.error = const ApiException(
          kind: ApiErrorKind.unauthorized, statusCode: 401, message: 'Invalid');
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'wrong');
      expect(container.read(authControllerProvider).status, AuthStatus.failure);
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider).context, isNull);
    });

    test('select tenant replaces context and JWT', () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)..result = contextFor();
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      repository.result =
          contextFor(tenantId: 'tenant-1', token: 'tenant-token');
      await container
          .read(authControllerProvider.notifier)
          .selectTenant('tenant-1');
      expect(container.read(authControllerProvider).context?.currentTenantId,
          'tenant-1');
      expect(container.read(authControllerProvider).context?.accessToken,
          'tenant-token');
      expect(storage.token, 'tenant-token');
    });

    for (final kind in [ApiErrorKind.forbidden, ApiErrorKind.network]) {
      test('select tenant $kind preserves prior context and JWT', () async {
        final storage = MemoryTokenStorage();
        final repository = StubAuthRepository(storage)..result = contextFor();
        final container = containerFor(storage, repository);
        addTearDown(container.dispose);
        container.read(authControllerProvider);
        await settleRestore();
        await container
            .read(authControllerProvider.notifier)
            .login('user@example.com', 'password');
        final previous = container.read(authControllerProvider).context;
        repository.error = ApiException(
            kind: kind,
            statusCode: kind == ApiErrorKind.forbidden ? 403 : null,
            message: 'Rejected');
        await container
            .read(authControllerProvider.notifier)
            .selectTenant('foreign-tenant');
        expect(container.read(authControllerProvider).status,
            AuthStatus.authenticated);
        expect(container.read(authControllerProvider).context?.currentTenantId,
            isNull);
        expect(storage.token, 'new-token');
        expect(container.read(authControllerProvider).context, same(previous));
      });
    }

    test('select tenant 401 cannot resurrect the expired session', () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)..result = contextFor();
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      // Reproduce the interceptor callback before the repository future throws.
      repository.beforeError = () => container.read(authControllerProvider.notifier).sessionExpired();
      repository.error = const ApiException(
          kind: ApiErrorKind.unauthorized,
          statusCode: 401,
          message: 'Unauthorized');
      await container
          .read(authControllerProvider.notifier)
          .selectTenant('tenant-1');
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider).context, isNull);
      expect(container.read(authControllerProvider).status,
          AuthStatus.sessionExpired);
    });

    test('successful logout clears token, context and state', () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)
        ..result = contextFor(tenantId: 'tenant-1');
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      await container.read(authControllerProvider.notifier).logout();
      expect(repository.logoutCalled, isTrue);
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider).context, isNull);
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);
      expect(
          redirectForAuth(container.read(authControllerProvider), '/dashboard'),
          '/login');
    });

    test('logout clears local session even if backend fails', () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)
        ..result = contextFor(tenantId: 'tenant-1');
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      repository.error =
          const ApiException(kind: ApiErrorKind.network, message: 'Offline');
      await container.read(authControllerProvider.notifier).logout();
      expect(repository.logoutCalled, isTrue);
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);
      expect(container.read(authControllerProvider).context, isNull);
    });

    test('authenticated 401 can be acknowledged to allow login', () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)
        ..result = contextFor(tenantId: 'tenant-1');
      final container = containerFor(storage, repository);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      container.read(authControllerProvider.notifier).sessionExpired();
      expect(container.read(authControllerProvider).status,
          AuthStatus.sessionExpired);
      expect(redirectForAuth(container.read(authControllerProvider), '/login'),
          '/session-expired');
      await container
          .read(authControllerProvider.notifier)
          .acknowledgeSessionExpired();
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider).context, isNull);
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);
      expect(redirectForAuth(container.read(authControllerProvider), '/login'),
          isNull);
    });
  });

  group('routing', () {
    test('unknown/loading route to splash', () {
      expect(
          redirectForAuth(const AuthState.unknown(), '/dashboard'), '/splash');
      expect(
          redirectForAuth(
              const AuthState(status: AuthStatus.loading), '/login'),
          '/splash');
    });

    test(
        'unauthenticated, expired and backend unavailable have dedicated routes',
        () {
      expect(
          redirectForAuth(const AuthState(status: AuthStatus.unauthenticated),
              '/dashboard'),
          '/login');
      expect(
          redirectForAuth(
              const AuthState(status: AuthStatus.sessionExpired), '/dashboard'),
          '/session-expired');
      expect(
          redirectForAuth(
              const AuthState(status: AuthStatus.backendUnavailable),
              '/dashboard'),
          '/backend-unavailable');
    });

    test('tenant selection and dashboard redirects', () {
      final withoutTenant =
          AuthState(status: AuthStatus.authenticated, context: contextFor());
      final withTenant = AuthState(
          status: AuthStatus.authenticated,
          context: contextFor(tenantId: 'tenant-1'));
      expect(redirectForAuth(withoutTenant, '/login'), '/select-tenant');
      expect(redirectForAuth(withTenant, '/login'), '/dashboard');
      expect(redirectForAuth(withTenant, '/select-tenant'), '/dashboard');
      expect(redirectForAuth(withoutTenant, '/dashboard'), '/select-tenant');
      expect(redirectForAuth(withoutTenant, '/jobs'), '/select-tenant');
      expect(redirectForAuth(withoutTenant, '/users'), '/select-tenant');
    });

    test('ADMIN without tenant can authenticate but not enter tenant routes',
        () {
      final admin = AuthState(
          status: AuthStatus.authenticated,
          context: contextFor(platformRole: 'ADMIN'));
      expect(redirectForAuth(admin, '/login'), '/select-tenant');
      expect(redirectForAuth(admin, '/dashboard'), '/select-tenant');
      expect(redirectForAuth(admin, '/campaigns'), '/select-tenant');
      expect(redirectForAuth(admin, '/prospects'), '/select-tenant');
      expect(redirectForAuth(admin, '/generate'), '/select-tenant');
      expect(redirectForAuth(admin, '/profile'), isNull);
    });
  });

  group('network session', () {
    test('Bearer is sent and an authenticated 401 clears the global session',
        () async {
      final storage = MemoryTokenStorage();
      final repository = StubAuthRepository(storage)
        ..result = contextFor(tenantId: 'tenant-1');
      final adapter = StubAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(overrides: [
        secureTokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
        apiClientProvider.overrideWith((ref) => ApiClient(
              config: const AppConfig(apiBaseUrl: 'http://localhost'),
              storage: storage,
              dio: dio,
              onUnauthorized: () async =>
                  ref.read(authControllerProvider.notifier).sessionExpired(),
            )),
      ]);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await container
          .read(authControllerProvider.notifier)
          .login('user@example.com', 'password');
      await container.read(apiClientProvider).get('/protected');
      expect(adapter.bearer, 'Bearer new-token');
      adapter.statusCode = 401;
      await expectLater(container.read(apiClientProvider).get('/protected'),
          throwsA(isA<ApiException>()));
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider).status,
          AuthStatus.sessionExpired);
    });

    test('403 is forbidden and preserves the authenticated session', () async {
      final storage = MemoryTokenStorage(token: 'existing-token');
      final repository = StubAuthRepository(storage)
        ..result = contextFor(tenantId: 'tenant-1');
      final adapter = StubAdapter()..statusCode = 403;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(overrides: [
        secureTokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
        apiClientProvider.overrideWith((ref) => ApiClient(
              config: const AppConfig(apiBaseUrl: 'http://localhost'),
              storage: storage,
              dio: dio,
              onUnauthorized: () async =>
                  ref.read(authControllerProvider.notifier).sessionExpired(),
            )),
      ]);
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await settleRestore();
      await expectLater(
        container.read(apiClientProvider).get('/protected'),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.forbidden)),
      );
      expect(storage.token, 'existing-token');
      expect(container.read(authControllerProvider).status,
          AuthStatus.authenticated);
    });
  });
}
