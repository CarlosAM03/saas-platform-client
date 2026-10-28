import 'dart:js_interop';

@JS('window.location.href')
external String get _href;
@JS('window.history.replaceState')
external void _replace(JSAny? state, String title, String value);
@JS('window.history.length')
external int get _length;
@JS('window.history.state')
external JSAny? get _state;
String location() => _href;
void replace(String value) => _replace(null, '', value);
int length() => _length;
bool hasState() => _state != null;
