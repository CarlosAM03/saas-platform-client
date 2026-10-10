/// Transport-independent binary response; the UI decides how to save it.
class ApiDownload {
  const ApiDownload(
      {required this.bytes, this.contentType, this.contentDisposition});
  final List<int> bytes;
  final String? contentType;
  final String? contentDisposition;
}
