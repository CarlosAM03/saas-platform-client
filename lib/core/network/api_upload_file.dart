import 'dart:typed_data';

/// Owns an immutable copy so preview and confirm reuse exactly the same bytes.
class ApiUploadFile {
  ApiUploadFile({required this.filename, required List<int> bytes})
      : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final String filename;
  final Uint8List bytes;
}
