import 'package:equatable/equatable.dart';

class TextChapter extends Equatable {
  final String title;
  final String text;

  const TextChapter({required this.title, required this.text});

  @override
  List<Object?> get props => [title, text];
}

/// Normalized chaptered text used by TXT / FB2 / unprotected MOBI readers.
class ParsedTextBook extends Equatable {
  final String title;
  final String author;
  final String? language;
  final List<TextChapter> chapters;

  const ParsedTextBook({
    required this.title,
    required this.author,
    required this.chapters,
    this.language,
  });

  bool get isEmpty => chapters.every((c) => c.text.trim().isEmpty);

  int get estimatedPages {
    if (chapters.isEmpty) return 0;
    final chars = chapters.fold<int>(0, (sum, c) => sum + c.text.length);
    // Rough page estimate (~1800 chars / "page") for progress UI.
    return (chars / 1800).ceil().clamp(1, 100000);
  }

  @override
  List<Object?> get props => [title, author, language, chapters];
}
