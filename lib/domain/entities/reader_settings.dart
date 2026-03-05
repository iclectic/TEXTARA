import 'package:equatable/equatable.dart';
import 'package:leaf_reader/core/constants/enums.dart';

class ReaderSettings extends Equatable {
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double horizontalMargin;
  final double pageWidth;
  final TextAlignment textAlignment;
  final bool hyphenationEnabled;
  final ReaderThemeMode themeMode;
  final String? customThemeId;

  const ReaderSettings({
    this.fontFamily = 'Literata',
    this.fontSize = 16.0,
    this.lineHeight = 1.6,
    this.paragraphSpacing = 12.0,
    this.horizontalMargin = 24.0,
    this.pageWidth = 1.0,
    this.textAlignment = TextAlignment.left,
    this.hyphenationEnabled = false,
    this.themeMode = ReaderThemeMode.light,
    this.customThemeId,
  });

  ReaderSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    double? horizontalMargin,
    double? pageWidth,
    TextAlignment? textAlignment,
    bool? hyphenationEnabled,
    ReaderThemeMode? themeMode,
    String? customThemeId,
  }) {
    return ReaderSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      pageWidth: pageWidth ?? this.pageWidth,
      textAlignment: textAlignment ?? this.textAlignment,
      hyphenationEnabled: hyphenationEnabled ?? this.hyphenationEnabled,
      themeMode: themeMode ?? this.themeMode,
      customThemeId: customThemeId ?? this.customThemeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'paragraphSpacing': paragraphSpacing,
        'horizontalMargin': horizontalMargin,
        'pageWidth': pageWidth,
        'textAlignment': textAlignment.name,
        'hyphenationEnabled': hyphenationEnabled,
        'themeMode': themeMode.name,
        'customThemeId': customThemeId,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
        fontFamily: json['fontFamily'] as String? ?? 'Literata',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
        lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
        paragraphSpacing:
            (json['paragraphSpacing'] as num?)?.toDouble() ?? 12.0,
        horizontalMargin:
            (json['horizontalMargin'] as num?)?.toDouble() ?? 24.0,
        pageWidth: (json['pageWidth'] as num?)?.toDouble() ?? 1.0,
        textAlignment: TextAlignment.values.firstWhere(
          (e) => e.name == json['textAlignment'],
          orElse: () => TextAlignment.left,
        ),
        hyphenationEnabled: json['hyphenationEnabled'] as bool? ?? false,
        themeMode: ReaderThemeMode.values.firstWhere(
          (e) => e.name == json['themeMode'],
          orElse: () => ReaderThemeMode.light,
        ),
        customThemeId: json['customThemeId'] as String?,
      );

  @override
  List<Object?> get props => [
        fontFamily,
        fontSize,
        lineHeight,
        paragraphSpacing,
        horizontalMargin,
        pageWidth,
        textAlignment,
        hyphenationEnabled,
        themeMode,
        customThemeId,
      ];
}
