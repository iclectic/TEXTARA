import 'package:equatable/equatable.dart';
import 'package:textara/core/constants/enums.dart';

class Highlight extends Equatable {
  final String id;
  final String bookId;
  final String? chapterId;
  final String selectedText;
  final HighlightColour colour;
  final String? note;
  final int startOffset;
  final int endOffset;
  final String? cfiRange;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Highlight({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.selectedText,
    this.colour = HighlightColour.yellow,
    this.note,
    required this.startOffset,
    required this.endOffset,
    this.cfiRange,
    required this.createdAt,
    required this.updatedAt,
  });

  Highlight copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? selectedText,
    HighlightColour? colour,
    String? note,
    int? startOffset,
    int? endOffset,
    String? cfiRange,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      selectedText: selectedText ?? this.selectedText,
      colour: colour ?? this.colour,
      note: note ?? this.note,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      cfiRange: cfiRange ?? this.cfiRange,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasNote => note != null && note!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapterId': chapterId,
        'selectedText': selectedText,
        'colour': colour.name,
        'note': note,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'cfiRange': cfiRange,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        chapterId: json['chapterId'] as String?,
        selectedText: json['selectedText'] as String? ?? '',
        colour: HighlightColour.values.firstWhere(
          (e) => e.name == json['colour'],
          orElse: () => HighlightColour.yellow,
        ),
        note: json['note'] as String?,
        startOffset: json['startOffset'] as int? ?? 0,
        endOffset: json['endOffset'] as int? ?? 0,
        cfiRange: json['cfiRange'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}

class Bookmark extends Equatable {
  final String id;
  final String bookId;
  final String? chapterId;
  final int pageNumber;
  final String? cfiLocation;
  final String? title;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.pageNumber,
    this.cfiLocation,
    this.title,
    required this.createdAt,
  });

  Bookmark copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    int? pageNumber,
    String? cfiLocation,
    String? title,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      pageNumber: pageNumber ?? this.pageNumber,
      cfiLocation: cfiLocation ?? this.cfiLocation,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapterId': chapterId,
        'pageNumber': pageNumber,
        'cfiLocation': cfiLocation,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        bookId: json['bookId'] as String,
        chapterId: json['chapterId'] as String?,
        pageNumber: json['pageNumber'] as int? ?? 0,
        cfiLocation: json['cfiLocation'] as String?,
        title: json['title'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}
