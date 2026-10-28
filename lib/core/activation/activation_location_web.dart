import 'dart:js_interop';

@JS('window.location.href')
external String get _href;
@JS('window.history.replaceState')
external void _replaceState(JSAny? state, String title, String url);

String currentLocation() => _href;
void replaceLocation(String location) => _replaceState(null, '', location);
