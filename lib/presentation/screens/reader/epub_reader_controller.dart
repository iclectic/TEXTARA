/// Imperative navigation into [EpubReaderView] (TOC / bookmark / search jumps).
class EpubReaderController {
  void Function(int chapterIndex)? _jumpToChapter;

  void attach(void Function(int chapterIndex) jumpToChapter) {
    _jumpToChapter = jumpToChapter;
  }

  void detach() {
    _jumpToChapter = null;
  }

  void jumpToChapter(int chapterIndex) {
    _jumpToChapter?.call(chapterIndex);
  }
}
