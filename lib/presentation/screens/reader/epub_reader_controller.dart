/// Imperative navigation into [EpubReaderView] (TOC / bookmark / search jumps).
class EpubReaderController {
  void Function(int chapterIndex)? _jumpToChapter;
  String Function()? _currentChapterText;

  void attach(
    void Function(int chapterIndex) jumpToChapter, {
    String Function()? currentChapterText,
  }) {
    _jumpToChapter = jumpToChapter;
    _currentChapterText = currentChapterText;
  }

  void detach() {
    _jumpToChapter = null;
    _currentChapterText = null;
  }

  void jumpToChapter(int chapterIndex) {
    _jumpToChapter?.call(chapterIndex);
  }

  String currentChapterText() => _currentChapterText?.call() ?? '';
}
