import 'package:equatable/equatable.dart';

class Collection extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int bookCount;

  const Collection({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.bookCount = 0,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookCount,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookCount: bookCount ?? this.bookCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Untitled Collection',
        description: json['description'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}
