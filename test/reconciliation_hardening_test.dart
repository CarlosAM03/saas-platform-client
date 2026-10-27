import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/app/app_providers.dart';
import 'package:saas_platform_client/core/config/app_config.dart';
import 'package:saas_platform_client/core/network/api_client.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/features/auth/state/auth_state.dart';
import 'package:saas_platform_client/shared/models/api_models.dart';
import 'foundation_auth_test.dart'
    show
        MemoryTokenStorage,
        StubAuthRepository,
        contextFor,
        containerFor,
        settleRestore;
import 'platform_repository_test.dart' show RecordingAdapter;

class DeferredAuth extends StubAuthRepository {
  DeferredAuth(super.storage);
  Completer<AuthContext>? pendingLogin, pendingRestore, pendingTenant;
  Completer<void>? pendingLogout;
  @override
  Future<AuthContext> login({
    required String email,
    required String password,
  }) => pendingLogin?.future ?? super.login(email: email, password: password);
  @override
  Future<AuthContext> me() => pendingRestore?.future ?? super.me();
  @override
  Future<AuthContext> selectTenant(String id) =>
      pendingTenant?.future ?? super.selectTenant(id);
  @override
  Future<void> logout() => pendingLogout?.future ?? super.logout();
}

class BlockingClearStorage extends MemoryTokenStorage {
  BlockingClearStorage() : super(token: 'old');
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> clearToken() async {
    started.complete();
    await release.future;
    await super.clearToken();
  }
}

void main() {
  test(
    'a session started during secure-storage deletion is not expired by the old 401',
    () async {
      final storage = BlockingClearStorage();
      final adapter = RecordingAdapter()..statusCode = 401;
      var expired = 0;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
        storage: storage,
        dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
        onUnauthorized: () async {
          expired++;
        },
      );
      final assertion = expectLater(
        client.get('/api/v1/campaigns'),
        throwsA(isA<ApiException>()),
      );
      await storage.started.future;
      storage.advanceSession();
      final writing = storage.tokenOperation(() => storage.writeToken('fresh'));
      storage.release.complete();
      await assertion;
      await writing;
      expect(storage.token, 'fresh');
      expect(expired, 0);
    },
  );
  test('a late login cannot resurrect logout', () async {
    final storage = MemoryTokenStorage();
    final repo = DeferredAuth(storage)..pendingLogin = Completer<AuthContext>();
    final container = containerFor(storage, repo);
    addTearDown(container.dispose);
    final auth = container.read(authControllerProvider.notifier);
    await settleRestore();
    final login = auth.login('test@example.com', 'password');
    await settleRestore();
    await auth.logout();
    repo.pendingLogin!.complete(contextFor(tenantId: 'tenant-1'));
    await login;
    expect(storage.token, isNull);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });
  test('a late session restore cannot resurrect logout', () async {
    final storage = MemoryTokenStorage(token: 'old');
    final repo = DeferredAuth(storage)
      ..pendingRestore = Completer<AuthContext>();
    final container = containerFor(storage, repo);
    addTearDown(container.dispose);
    final auth = container.read(authControllerProvider.notifier);
    await settleRestore();
    await auth.logout();
    repo.pendingRestore!.complete(contextFor());
    await settleRestore();
    expect(storage.token, isNull);
    expect(container.read(authControllerProvider).context, isNull);
  });
  test('a late tenant response cannot replace a subsequent login', () async {
    final storage = MemoryTokenStorage(token: 'old');
    final repo = DeferredAuth(storage)
      ..result = contextFor(tenantId: 'tenant-1');
    final container = containerFor(storage, repo);
    addTearDown(container.dispose);
    final auth = container.read(authControllerProvider.notifier);
    await settleRestore();
    repo.pendingTenant = Completer<AuthContext>();
    final switching = auth.selectTenant('tenant-2');
    await auth.logout();
    repo.result = contextFor(tenantId: 'tenant-3', token: 'fresh');
    await auth.login('test@example.com', 'password');
    repo.pendingTenant!.complete(
      contextFor(tenantId: 'tenant-2', token: 'stale'),
    );
    await switching;
    expect(storage.token, 'fresh');
    expect(
      container.read(authControllerProvider).context?.currentTenantId,
      'tenant-3',
    );
  });
  test('a delayed remote logout cannot clear a newer session', () async {
    final storage = MemoryTokenStorage(token: 'old');
    final repo = DeferredAuth(storage)
      ..result = contextFor(tenantId: 'tenant-1');
    final container = containerFor(storage, repo);
    addTearDown(container.dispose);
    final auth = container.read(authControllerProvider.notifier);
    await settleRestore();
    repo.pendingLogout = Completer<void>();
    final logout = auth.logout();
    expect(container.read(authControllerProvider).context, isNull);
    repo.result = contextFor(tenantId: 'tenant-2', token: 'fresh');
    await auth.login('test@example.com', 'password');
    repo.pendingLogout!.completeError(StateError('offline'));
    await logout;
    expect(storage.token, 'fresh');
    expect(
      container.read(authControllerProvider).context?.currentTenantId,
      'tenant-2',
    );
  });
  test(
    'late 401 is ignored even when a new session uses identical token bytes',
    () async {
      final storage = MemoryTokenStorage(token: 'same-token');
      final adapter = RecordingAdapter()..statusCode = 401;
      adapter.beforeReply = () async {
        storage.advanceSession();
      };
      var expired = 0;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
        storage: storage,
        dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
        onUnauthorized: () async {
          expired++;
        },
      );
      await expectLater(
        client.get('/api/v1/campaigns'),
        throwsA(isA<ApiException>()),
      );
      expect(storage.token, 'same-token');
      expect(expired, 0);
    },
  );
  test(
    'a queued request is canceled instead of attaching the next session JWT',
    () async {
      final storage = MemoryTokenStorage(token: 'old');
      final lock = Completer<void>();
      final blocked = storage.tokenOperation(() => lock.future);
      final adapter = RecordingAdapter();
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
        storage: storage,
        dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
      );
      final request = client.get('/api/v1/campaigns');
      final assertion = expectLater(request, throwsA(isA<ApiException>()));
      storage.advanceSession();
      storage.token = 'fresh';
      lock.complete();
      await blocked;
      await assertion;
      expect(adapter.requests, isEmpty);
      expect(storage.token, 'fresh');
    },
  );
  test(
    'a compare-and-clear operation cannot erase a queued token replacement',
    () async {
      final storage = MemoryTokenStorage(token: 'old');
      final release = Completer<void>();
      final clearing = storage.tokenOperation(() async {
        await release.future;
        await storage.clearToken();
      });
      final writing = storage.tokenOperation(() => storage.writeToken('fresh'));
      release.complete();
      await Future.wait([clearing, writing]);
      expect(storage.token, 'fresh');
    },
  );
  for (final url in [
    'https://api.example.test/api/v1',
    'https://user:secret@api.example.test',
    'https://api.example.test?tenantId=x',
    'http://api.example.test',
    'https://api.example.test/#x',
    ' https://api.example.test',
  ]) {
    test('rejects invalid API origin $url', () {
      expect(() => AppConfig.validateApiBaseUrl(url), throwsArgumentError);
    });
  }
  test('normalizes an HTTPS origin and keeps local development explicit', () {
    expect(
      AppConfig.validateApiBaseUrl('https://api.example.test/'),
      'https://api.example.test',
    );
    expect(
      AppConfig.validateApiBaseUrl('http://localhost:3000'),
      'http://localhost:3000',
    );
    expect(
      () => AppConfig.validateApiBaseUrl(
        'http://localhost:3000',
        requireHttps: true,
      ),
      throwsArgumentError,
    );
  });
}
