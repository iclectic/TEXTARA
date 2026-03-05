enum BookFormat { epub, pdf }

enum ReadingStatus { notStarted, reading, finished }

enum LibraryViewMode { grid, list }

enum LibrarySortField { recentlyOpened, title, author, progress, lastAdded }

enum SortOrder { ascending, descending }

enum ReaderThemeMode {
  light,
  dark,
  trueBlack,
  sepia,
  highContrast,
}

enum HighlightColour {
  yellow,
  green,
  blue,
  pink,
  orange,
  purple,
  red,
  teal,
}

enum TextAlignment { left, right, centre, justify }

enum ExportFormat { markdown, pdf, json }

enum ImportSource { filePicker, shareIntent, openWith, dragDrop }

enum BackupScope { metadataOnly, withFiles }

enum TtsState { playing, paused, stopped }
