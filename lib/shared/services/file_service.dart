import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_upload_file.dart';
import '../../core/errors/api_exception.dart';

const maxCsvBytes = 5 * 1024 * 1024;

abstract interface class FileService {
  Future<ApiUploadFile?> pickCsv();
  Future<bool> save(String filename, List<int> bytes);
}

final fileServiceProvider = Provider<FileService>((ref) => NativeFileService());

class NativeFileService implements FileService {
  @override
  Future<ApiUploadFile?> pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withReadStream: true);
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > maxCsvBytes) {
      throw const ApiException(
          kind: ApiErrorKind.payloadTooLarge,
          message: 'El archivo supera 5 MB.');
    }
    final bytes = BytesBuilder(copy: false);
    if (file.bytes != null) {
      bytes.add(file.bytes!);
    } else if (file.readStream != null) {
      await for (final chunk in file.readStream!) {
        if (bytes.length + chunk.length > maxCsvBytes) {
          throw const ApiException(
              kind: ApiErrorKind.payloadTooLarge,
              message: 'El archivo supera 5 MB.');
        }
        bytes.add(chunk);
      }
    } else {
      throw const ApiException(
          kind: ApiErrorKind.badRequest,
          message: 'No se pudo leer el archivo. Selecciónalo nuevamente.');
    }
    if (bytes.length == 0) {
      throw const ApiException(
          kind: ApiErrorKind.badRequest, message: 'El archivo está vacío.');
    }
    return ApiUploadFile(filename: file.name, bytes: bytes.takeBytes());
  }

  @override
  Future<bool> save(String filename, List<int> bytes) async =>
      await FilePicker.platform
          .saveFile(fileName: filename, bytes: Uint8List.fromList(bytes)) !=
      null;
}
