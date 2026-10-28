import 'api_exception.dart';

class ErrorMapper {
  const ErrorMapper();

  String userMessage(Object error) {
    if (error is ApiException) {
      return switch (error.kind) {
        ApiErrorKind.badRequest => 'Revisa los datos ingresados.',
        ApiErrorKind.unauthorized =>
          'Credenciales inválidas o sesión expirada.',
        ApiErrorKind.forbidden =>
          'No tienes permisos para realizar esta acción.',
        ApiErrorKind.notFound => 'No se encontró la información solicitada.',
        ApiErrorKind.conflict =>
          'La operación entra en conflicto con el estado actual.',
        ApiErrorKind.payloadTooLarge => 'El archivo supera el límite de 5 MB.',
        ApiErrorKind.rateLimited =>
          'Demasiadas solicitudes. Intenta nuevamente.',
        ApiErrorKind.serviceUnavailable =>
          'El servicio no está disponible temporalmente.',
        ApiErrorKind.network => 'No fue posible conectar con el servidor.',
        ApiErrorKind.unknown => 'No fue posible completar la operación.',
      };
    }
    if (error is FormatException || error is TypeError) {
      // Never include parser messages: they may contain response values or secrets.
      return 'La respuesta del servidor no coincide con el formato esperado.';
    }
    return 'No fue posible completar la operación.';
  }
}
