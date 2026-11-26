import 'dart:convert';
import '../../../core/errors/api_exception.dart';

String? registrationName(String? value) => value == null || value.trim().isEmpty
    ? 'Campo obligatorio'
    : value.trim().runes.length > 120
    ? 'Máximo 120 caracteres'
    : null;
String? registrationSlug(String? value) =>
    value != null &&
        value.length >= 3 &&
        value.length <= 63 &&
        RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])$').hasMatch(value)
    ? null
    : 'Usa 3–63 minúsculas, números o guiones interiores';
String? registrationEmail(String? value) =>
    value != null &&
        value.trim().length <= 254 &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? null
    : 'Escribe un correo válido (máximo 254 caracteres)';

String? initialPassword(String? value) {
  if (value == null || value.runes.length < 10) {
    return 'Usa al menos 10 caracteres Unicode';
  }
  if (utf8.encode(value).length > 72) return 'Máximo 72 bytes UTF-8';
  if (!RegExp(r'\p{L}', unicode: true).hasMatch(value) ||
      !RegExp(r'\p{N}', unicode: true).hasMatch(value) ||
      !RegExp(r'[^\p{L}\p{N}]', unicode: true).hasMatch(value)) {
    return 'Incluye una letra, un número y un carácter especial';
  }
  return null;
}

const invalidActivationMessage =
    'No se pudo usar este enlace. Solicita uno nuevo al administrador.';
String registrationError(Object error, {bool activation = false}) {
  final status = error is ApiException ? error.statusCode : null;
  return switch (status) {
    400 => 'Revisa los campos y las reglas indicadas.',
    401 =>
      activation
          ? invalidActivationMessage
          : 'La sesión no es válida. Inicia sesión nuevamente.',
    403 => 'No tienes permisos para realizar esta acción.',
    404 => 'No se encontró onboarding para esta organización.',
    409 =>
      'No se pudo realizar la operación por un conflicto de datos o estado.',
    429 =>
      'Se alcanzó el límite temporal. Espera antes de volver a intentarlo.',
    503 =>
      activation
          ? 'La activación no está disponible temporalmente.'
          : 'El registro asistido está deshabilitado temporalmente.',
    _ =>
      activation
          ? 'No se confirmó la activación. Solicita ayuda al administrador; no reutilices el enlace.'
          : 'No se pudo confirmar la operación. Consulta las organizaciones y su estado antes de repetir un registro.',
  };
}
