class AppConstants {
  AppConstants._();

  static const String appName = 'Textara';
  static const String appTagline = 'Your books, beautifully read.';
  static const String appVersion = '1.0.0';

  static const int maxLibrarySize = 10000;
  static const int coverCacheSize = 500;
  static const int searchResultLimit = 50;
  static const int importBatchSize = 10;

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const double minFontSize = 10.0;
  static const double maxFontSize = 36.0;
  static const double defaultFontSize = 16.0;
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 3.0;
  static const double defaultLineHeight = 1.6;
  static const double minMargin = 8.0;
  static const double maxMargin = 64.0;
  static const double defaultMargin = 24.0;

  static const List<String> supportedExtensions = [
    'epub',
    'pdf',
    'txt',
    'fb2',
    'mobi',
    'azw',
    'azw3',
  ];

  /// Human-readable import formats for empty states and error copy.
  static const String supportedFormatsLabel =
      'EPUB, PDF, TXT, FB2, and DRM-free MOBI/AZW';

  /// Soft per-file ceiling surfaced in UX (enforced in ImportSecurityPolicy).
  static const int maxImportFileBytes = 500 * 1024 * 1024;

  static const String prefKeyFirstRun = 'first_run';
  static const String prefKeyTheme = 'theme_mode';
  static const String prefKeyLibraryView = 'library_view';
  static const String prefKeyReducedMotion = 'reduced_motion';
  static const String prefKeyHighContrast = 'high_contrast';
  static const String prefKeyDyslexiaMode = 'dyslexia_mode';
  static const String prefKeyLowStimulation = 'low_stimulation';
  static const String prefKeyReaderDefaults = 'reader_defaults';
  static const String prefKeyReaderBrightness = 'reader_brightness';
  static const String prefKeyDictionaryOnline = 'dictionary_online_fallback';
  static const String prefKeyDictionaryCache = 'dictionary_lookup_cache';

  /// Application-scoped brightness when the user has not chosen a custom value.
  static const double defaultReaderBrightness = 1.0;
  static const double minReaderBrightness = 0.05;
  static const double maxReaderBrightness = 1.0;

  /// Debounce window for persisting reading progress during rapid paging.
  static const Duration readingProgressDebounce = Duration(milliseconds: 500);

  /// Soft memory budget for pdfrx page-image cache (large PDFs).
  static const int pdfMaxImageBytesCachedOnMemory = 64 * 1024 * 1024;

  /// Nearby-page cache extent ratios for PDF viewer (viewport multiples).
  static const double pdfHorizontalCacheExtent = 0.75;
  static const double pdfVerticalCacheExtent = 0.75;

  static const String dictionaryAssetPath = 'assets/dictionary/en_core.json';
  static const String dictionaryOnlineEndpoint =
      'https://api.dictionaryapi.dev/api/v2/entries/en/';
  static const int dictionaryCacheMaxEntries = 200;

  static const String backupFileExtension = 'textara';
  static const String backupMimeType = 'application/json';
}
