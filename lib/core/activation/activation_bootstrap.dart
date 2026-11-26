import 'activation_location_stub.dart'
    if (dart.library.js_interop) 'activation_location_web.dart'
    as platform;

/// One-shot transfer from browser URL to the activation controller. Never stored
/// in router state, Riverpod state/observers, persistence or diagnostics.
class ActivationBootstrap {
  ActivationBootstrap({this.isActivation = false, String? code}) : _code = code;
  final bool isActivation;
  String? _code;
  String? takeCode() {
    final code = _code;
    _code = null;
    return code;
  }

  void clear() => _code = null;
  @override
  String toString() => 'ActivationBootstrap([redacted])';
}

ActivationBootstrap captureActivationLink() => captureActivationLocation(
  platform.currentLocation,
  platform.replaceLocation,
);

/// Scrub BEFORE parsing the credential and BEFORE initializing Flutter/router.
/// Clearing history.state also prevents restoration of a preexisting raw URI.
ActivationBootstrap captureActivationLocation(
  String Function() read,
  void Function(String) replace,
) {
  final location = read();
  final hash = location.indexOf('#');
  if (hash < 0 ||
      location.substring(hash + 1).split('?').first != '/activate') {
    return ActivationBootstrap();
  }
  final base = Uri.tryParse(location.substring(0, hash));
  if (base == null) {
    throw StateError('No se pudo limpiar la ubicación de activación.');
  }
  try {
    // Keep harmless host query parameters (Flutter's web test runner needs
    // managerUrl), while replacing the fragment that contained the secret.
    replace(base.replace(fragment: '/activate').toString());
  } catch (_) {
    throw StateError('No se pudo limpiar la ubicación de activación.');
  }
  String? code;
  try {
    final parameters = Uri.parse(
      location.substring(hash + 1),
    ).queryParametersAll;
    final codes = parameters['code'];
    if (codes?.length == 1 && codes!.single.length >= 40) code = codes.single;
  } catch (_) {
    /* Invalid link: clean URL, no diagnostics containing input. */
  }
  return ActivationBootstrap(isActivation: true, code: code);
}
