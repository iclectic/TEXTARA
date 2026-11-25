/// Something another app, the Files app, or a `textara://` link asked
/// Textara to handle.
enum IncomingKind { file, book }

class IncomingRequest {
  final IncomingKind kind;
  final String value;

  const IncomingRequest({required this.kind, required this.value});
}

/// Turns the platform channel payload into importable files and book links.
///
/// Files must look like EPUB or PDF. Book ids are the local library id from
/// `textara://book/<id>`. Anything else is dropped before it can touch the
/// importer.
class IncomingPayload {
  static final RegExp _bookId = RegExp(r'^[A-Za-z0-9_-]{1,80}$');

  static List<IncomingRequest> parse(Object? raw) {
    if (raw is! List) return const [];
    final requests = <IncomingRequest>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final type = item['type'];
      final value = item['value'];
      if (value is! String) continue;
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (type == 'file' && _isBookFile(trimmed)) {
        requests.add(IncomingRequest(kind: IncomingKind.file, value: trimmed));
      } else if (type == 'book' && _bookId.hasMatch(trimmed)) {
        requests.add(IncomingRequest(kind: IncomingKind.book, value: trimmed));
      }
    }
    return requests;
  }

  static bool _isBookFile(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return false;
    final extension = name.substring(dot + 1).toLowerCase();
    return extension == 'epub' || extension == 'pdf';
  }
}
