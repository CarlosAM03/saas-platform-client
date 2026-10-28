import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saas_platform_client/core/errors/api_exception.dart';
import 'package:saas_platform_client/shared/services/file_service.dart';

class PickerStub extends FilePicker {
  FilePickerResult? result;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    expect(type, FileType.custom);
    expect(allowedExtensions, ['csv']);
    expect(allowMultiple, isFalse);
    expect(withReadStream, isTrue);
    return result;
  }
}

void main() {
  late PickerStub picker;
  setUp(() {
    picker = PickerStub();
    FilePicker.platform = picker;
  });
  test('canceling selection performs no upload', () async {
    expect(await NativeFileService().pickCsv(), isNull);
  });
  test('CSV selection reads bytes at the exact 5 MiB boundary', () async {
    picker.result = FilePickerResult([
      PlatformFile(
        name: 'data.csv',
        size: maxCsvBytes,
        bytes: Uint8List(maxCsvBytes),
      ),
    ]);
    expect((await NativeFileService().pickCsv())!.bytes.length, maxCsvBytes);
  });
  test('oversized declared file is rejected before reading', () async {
    picker.result = FilePickerResult([
      PlatformFile(name: 'data.csv', size: maxCsvBytes + 1),
    ]);
    await expectLater(
      NativeFileService().pickCsv(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.payloadTooLarge,
        ),
      ),
    );
  });
  test(
    'a stream cannot bypass the 5 MiB bound with an incorrect declared size',
    () async {
      picker.result = FilePickerResult([
        PlatformFile(
          name: 'data.csv',
          size: 1,
          readStream: Stream.fromIterable([
            Uint8List(maxCsvBytes),
            Uint8List(1),
          ]),
        ),
      ]);
      await expectLater(
        NativeFileService().pickCsv(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.payloadTooLarge,
          ),
        ),
      );
    },
  );
  test('buffered bytes cannot bypass the declared bound either', () async {
    picker.result = FilePickerResult([
      PlatformFile(
        name: 'data.csv',
        size: 1,
        bytes: Uint8List(maxCsvBytes + 1),
      ),
    ]);
    await expectLater(
      NativeFileService().pickCsv(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.payloadTooLarge,
        ),
      ),
    );
  });
  test('empty files produce a readable error', () async {
    picker.result = FilePickerResult([
      PlatformFile(name: 'empty.csv', size: 0, bytes: Uint8List(0)),
    ]);
    await expectLater(
      NativeFileService().pickCsv(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.badRequest,
        ),
      ),
    );
  });
}
