Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected JSON object');
  }
  return Map<String, dynamic>.from(value);
}

T requiredValue<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (!json.containsKey(key) || value is! T) {
    throw FormatException('Invalid required field: $key');
  }
  return value;
}

T? optionalValue<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! T) throw FormatException('Invalid field: $key');
  return value;
}

T? nullableValue<T>(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing nullable field: $key');
  }
  return optionalValue<T>(json, key);
}

T enumValue<T extends Enum>(Object? value, List<T> values) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  throw FormatException('Invalid enum value: $value');
}

DateTime dateValue(Map<String, dynamic> json, String key) =>
    DateTime.parse(requiredValue<String>(json, key));
DateTime? nullableDate(Map<String, dynamic> json, String key) {
  final value = nullableValue<String>(json, key);
  return value == null ? null : DateTime.parse(value);
}
