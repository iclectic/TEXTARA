enum BookFormat {
  epub,
  pdf,
  txt,
  fb2,

  /// PalmDB Mobipocket / unprotected AZW family (DRM never decrypted).
  mobi,
}

enum ReadingStatus { notStarted, reading, finished }

enum LibraryViewMode { grid, list }

enum LibrarySortField { recentlyOpened, title, author, progress, lastAdded }

enum SortOrder { ascending, descending }

enum ReaderThemeMode { light, dark, blue, trueBlack, sepia, highContrast }

enum HighlightColour { yellow, green, blue, pink, orange, purple, red, teal }

enum TextAlignment { left, right, centre, justify }

enum ExportFormat { markdown, pdf, json }

enum ImportSource { filePicker, shareIntent, openWith, dragDrop }

enum BackupScope { metadataOnly, withFiles }

enum TtsState { playing, paused, stopped }
