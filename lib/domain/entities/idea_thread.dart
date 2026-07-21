import 'package:equatable/equatable.dart';
import 'package:textara/domain/entities/annotation.dart';

class IdeaThread extends Equatable {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final String? synthesisNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int evidenceCount;

  const IdeaThread({
    required this.id,
    required this.title,
    this.description,
    this.tags = const [],
    this.synthesisNote,
    required this.createdAt,
    required this.updatedAt,
    this.evidenceCount = 0,
  });

  IdeaThread copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    String? synthesisNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? evidenceCount,
  }) {
    return IdeaThread(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      synthesisNote: synthesisNote ?? this.synthesisNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      evidenceCount: evidenceCount ?? this.evidenceCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'tags': tags,
    'synthesisNote': synthesisNote,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory IdeaThread.fromJson(Map<String, dynamic> json) => IdeaThread(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled Thread',
    description: json['description'] as String?,
    tags:
        (json['tags'] as List<dynamic>?)?.whereType<String>().toList() ??
        const [],
    synthesisNote: json['synthesisNote'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  @override
  List<Object?> get props => [id];
}

class ThreadHighlightLink extends Equatable {
  final String threadId;
  final String highlightId;
  final String? reflection;
  final int sortOrder;
  final DateTime addedAt;

  const ThreadHighlightLink({
    required this.threadId,
    required this.highlightId,
    this.reflection,
    required this.sortOrder,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'threadId': threadId,
    'highlightId': highlightId,
    'reflection': reflection,
    'sortOrder': sortOrder,
    'addedAt': addedAt.toIso8601String(),
  };

  factory ThreadHighlightLink.fromJson(Map<String, dynamic> json) =>
      ThreadHighlightLink(
        threadId: json['threadId'] as String,
        highlightId: json['highlightId'] as String,
        reflection: json['reflection'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
        addedAt:
            DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [threadId, highlightId];
}

class ThreadEvidence extends Equatable {
  final String threadId;
  final Highlight highlight;
  final String bookTitle;
  final String? reflection;
  final int sortOrder;
  final DateTime addedAt;

  const ThreadEvidence({
    required this.threadId,
    required this.highlight,
    required this.bookTitle,
    this.reflection,
    required this.sortOrder,
    required this.addedAt,
  });

  bool get hasReflection => reflection != null && reflection!.trim().isNotEmpty;

  @override
  List<Object?> get props => [threadId, highlight.id];
}
