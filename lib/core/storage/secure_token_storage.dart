import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);

class SecureTokenStorage {
  const SecureTokenStorage(this._storage);

  // Serialize read/compare/clear with token replacement, including test stores.
  static final _pending = Expando<Future<void>>();
  static final _revisions = Expando<int>();
  int get sessionRevision => _revisions[this] ?? 0;
  void advanceSession() => _revisions[this] = sessionRevision + 1;
  Future<T> tokenOperation<T>(Future<T> Function() action) {
    final result = (_pending[this] ?? Future<void>.value()).then(
      (_) => action(),
    );
    _pending[this] = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static const tokenKey = 'saas_platform.jwt';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: tokenKey);
  Future<void> writeToken(String token) =>
      _storage.write(key: tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: tokenKey);
}
