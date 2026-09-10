import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);

class SecureTokenStorage {
  const SecureTokenStorage(this._storage);

  static const tokenKey = 'saas_platform.jwt';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: tokenKey);
  Future<void> writeToken(String token) => _storage.write(key: tokenKey, value: token);
  Future<void> clearToken() => _storage.delete(key: tokenKey);
}
