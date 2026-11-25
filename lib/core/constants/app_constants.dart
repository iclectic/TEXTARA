class AppConstants {
  AppConstants._();

  static const String appName = 'Textara';
  static const String appTagline = 'Your books, beautifully read.';
  static const String appVersion = '1.0.0';

  /// Shortest window side that switches Library and Threads to two panes.
  static const double tabletShortestSide = 600;

  /// Platform channel for shared files, document opens, and book links.
  static const String incomingChannel = 'com.textara.textara/incoming';

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

  static const List<String> supportedExtensions = ['epub', 'pdf'];

  static const String prefKeyFirstRun = 'first_run';
  static const String prefKeyTheme = 'theme_mode';
  static const String prefKeyLibraryView = 'library_view';
  static const String prefKeyReducedMotion = 'reduced_motion';
  static const String prefKeyHighContrast = 'high_contrast';
  static const String prefKeyDyslexiaMode = 'dyslexia_mode';
  static const String prefKeyLowStimulation = 'low_stimulation';
  static const String prefKeyReaderDefaults = 'reader_defaults';
  static const String prefKeyThreadInsights = 'thread_insights_enabled';
  static const String prefKeyReadingReminder = 'reading_reminder_enabled';

  static const String backupFileExtension = 'textara';
  static const String backupMimeType = 'application/json';

  /// Bundled sample EPUB used by onboarding ("Get started with a sample book").
  static const String sampleBookAsset = 'assets/sample/welcome_to_textara.epub';
}
