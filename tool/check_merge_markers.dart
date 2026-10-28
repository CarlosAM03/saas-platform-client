import 'dart:io';

void main() {
  final marker = RegExp(r'^(<<<<<<< |=======$|>>>>>>> )', multiLine: true);
  final files = [
    File('README.md'),
    for (final root in ['lib', 'test', 'web'])
      ...Directory(root).listSync(recursive: true).whereType<File>(),
  ];
  final failures = <String>[];
  for (final file in files.where(
    (f) => ['.dart', '.md', '.html', '.json'].any(f.path.endsWith),
  )) {
    if (marker.hasMatch(file.readAsStringSync())) failures.add(file.path);
  }
  if (failures.isNotEmpty) {
    throw StateError('Unresolved merge markers: ${failures.join(', ')}');
  }
  stdout.writeln('No unresolved merge markers.');
}
