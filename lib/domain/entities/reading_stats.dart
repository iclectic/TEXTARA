import 'package:equatable/equatable.dart';

class ReadingStats extends Equatable {
  final int totalSecondsRead;
  final int booksFinished;
  final int highlightCount;
  final int booksInLibrary;

  const ReadingStats({
    required this.totalSecondsRead,
    required this.booksFinished,
    required this.highlightCount,
    required this.booksInLibrary,
  });

  int get totalMinutesRead => (totalSecondsRead / 60).round();

  @override
  List<Object?> get props => [
    totalSecondsRead,
    booksFinished,
    highlightCount,
    booksInLibrary,
  ];
}
