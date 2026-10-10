import '../core/network/api_client.dart';
import '../shared/models/api_models.dart' show unwrapObject;
import 'models.dart';

class HealthApi {
  const HealthApi(this._client);
  final ApiClient _client;
  Future<Health> health() async =>
      Health.fromJson(unwrapObject(await _client.get('/api/v1/health')));
  Future<Health> live() async =>
      Health.fromJson(unwrapObject(await _client.get('/api/v1/health/live')));
  Future<Health> ready() async =>
      Health.fromJson(unwrapObject(await _client.get('/api/v1/health/ready')));
}
