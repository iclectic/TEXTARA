import 'package:equatable/equatable.dart';
import 'package:leaf_reader/core/constants/enums.dart';

class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String filePath;
  final BookFormat format;
  final String? coverPath;
  final ReadingStatus readingStatus;
  final double readingProgress;
  final int currentPage;
  final String? currentChapterId;
  final int totalPages;
  final DateTime dateAdded;
  final DateTime? lastOpenedAt;
  final bool isFavourite;
  final List<String> tags;
  final List<String> collectionIds;
  final int fileSizeBytes;
  final String? language;
  final String? publisher;
  final String? isbn;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.filePath,
    required this.format,
    this.coverPath,
    this.readingStatus = ReadingStatus.notStarted,
    this.readingProgress = 0.0,
    this.currentPage = 0,
    this.currentChapterId,
    this.totalPages = 0,
    required this.dateAdded,
    this.lastOpenedAt,
    this.isFavourite = false,
    this.tags = const [],
    this.collectionIds = const [],
    this.fileSizeBytes = 0,
    this.language,
    this.publisher,
    this.isbn,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? filePath,
    BookFormat? format,
    String? coverPath,
    ReadingStatus? readingStatus,
    double? readingProgress,
    int? currentPage,
    String? currentChapterId,
    int? totalPages,
    DateTime? dateAdded,
    DateTime? lastOpenedAt,
    bool? isFavourite,
    List<String>? tags,
    List<String>? collectionIds,
    int? fileSizeBytes,
    String? language,
    String? publisher,
    String? isbn,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      coverPath: coverPath ?? this.coverPath,
      readingStatus: readingStatus ?? this.readingStatus,
      readingProgress: readingProgress ?? this.readingProgress,
      currentPage: currentPage ?? this.currentPage,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      totalPages: totalPages ?? this.totalPages,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isFavourite: isFavourite ?? this.isFavourite,
      tags: tags ?? this.tags,
      collectionIds: collectionIds ?? this.collectionIds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      language: language ?? this.language,
      publisher: publisher ?? this.publisher,
      isbn: isbn ?? this.isbn,
    );
  }

  String get formattedProgress => '${(readingProgress * 100).toStringAsFixed(0)}%';

  bool get isEpub => format == BookFormat.epub;
  bool get isPdf => format == BookFormat.pdf;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'description': description,
        'filePath': filePath,
        'format': format.name,
        'coverPath': coverPath,
        'readingStatus': readingStatus.name,
        'readingProgress': readingProgress,
        'currentPage': currentPage,
        'currentChapterId': currentChapterId,
        'totalPages': totalPages,
        'dateAdded': dateAdded.toIso8601String(),
        'lastOpenedAt': lastOpenedAt?.toIso8601String(),
        'isFavourite': isFavourite,
        'tags': tags,
        'collectionIds': collectionIds,
        'fileSizeBytes': fileSizeBytes,
        'language': language,
        'publisher': publisher,
        'isbn': isbn,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled',
        author: json['author'] as String? ?? 'Unknown Author',
        description: json['description'] as String?,
        filePath: json['filePath'] as String,
        format: BookFormat.values.firstWhere(
          (e) => e.name == json['format'],
          orElse: () => BookFormat.epub,
        ),
        coverPath: json['coverPath'] as String?,
        readingStatus: ReadingStatus.values.firstWhere(
          (e) => e.name == json['readingStatus'],
          orElse: () => ReadingStatus.notStarted,
        ),
        readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0.0,
        currentPage: json['currentPage'] as int? ?? 0,
        currentChapterId: json['currentChapterId'] as String?,
        totalPages: json['totalPages'] as int? ?? 0,
        dateAdded: DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
            DateTime.now(),
        lastOpenedAt: json['lastOpenedAt'] != null
            ? DateTime.tryParse(json['lastOpenedAt'] as String)
            : null,
        isFavourite: json['isFavourite'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        collectionIds: (json['collectionIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        language: json['language'] as String?,
        publisher: json['publisher'] as String?,
        isbn: json['isbn'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
