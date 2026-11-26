import 'dart:js_interop';

@JS('window.location.href')
external String get _href;
@JS('window.history.replaceState')
external void _replaceState(JSAny? state, String title, String url);
@JS('window.__prospectorTakeActivationLocation')
external JSFunction? get _takeEarlyLocation;

String currentLocation() {
  final early = _takeEarlyLocation?.callAsFunction()?.dartify();
  return early is String ? early : _href;
}
void replaceLocation(String location) => _replaceState(null, '', location);
