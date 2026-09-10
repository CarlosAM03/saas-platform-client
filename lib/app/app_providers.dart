import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_token_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/state/auth_state.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureTokenStorageProvider);
  return ApiClient(config: config, storage: storage);
});

final errorMapperProvider = Provider<ErrorMapper>((ref) => const ErrorMapper());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
