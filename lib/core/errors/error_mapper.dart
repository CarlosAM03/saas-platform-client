import 'api_exception.dart';

class ErrorMapper {
  const ErrorMapper();
  String userMessage(Object error) {
<<<<<<< Updated upstream
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
    return 'No fue posible completar la operación.';
=======
    if (error is! ApiException) {
      return 'No fue posible completar la operación. Intenta nuevamente.';
    }
    return switch (error.kind) {
      ApiErrorKind.unauthorized =>
        'Tu sesión venció o las credenciales son incorrectas.',
      ApiErrorKind.forbidden =>
        'Tu cuenta no tiene permiso para realizar esta acción.',
      ApiErrorKind.notFound =>
        'El registro ya no está disponible en esta organización.',
      ApiErrorKind.conflict =>
        'El registro ya existe o tiene información relacionada. Revisa los datos.',
      ApiErrorKind.rateLimited =>
        'Demasiados intentos. Espera un momento y vuelve a intentar.',
      ApiErrorKind.network =>
        'No pudimos conectar. Revisa tu conexión e intenta nuevamente.',
      ApiErrorKind.serviceUnavailable =>
        'Esta función no está disponible por el momento.',
      ApiErrorKind.badRequest =>
        'Revisa los datos del formulario. ${error.message}',
      _ => 'No fue posible completar la operación. Intenta nuevamente.',
    };
>>>>>>> Stashed changes
  }
}
