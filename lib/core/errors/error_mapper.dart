import 'api_exception.dart';

class ErrorMapper {
  const ErrorMapper();

  String userMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'No fue posible completar la operación.';
  }
}
