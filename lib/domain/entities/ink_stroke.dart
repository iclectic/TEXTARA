import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum InkTool {
  /// Drawing disabled — reader scroll/selection work normally.
  off,
  pen,
  eraser,
  highlighter,
}

class InkPoint extends Equatable {
  final double x;
  final double y;

  /// 0.0–1.0 when the pointer reports pressure; otherwise 0.5.
  final double pressure;

  const InkPoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'p': pressure,
      };

  factory InkPoint.fromJson(Map<String, dynamic> json) => InkPoint(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        pressure: ((json['p'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      );

  Offset get offset => Offset(x, y);

  @override
  List<Object?> get props => [x, y, pressure];
}

class InkStroke extends Equatable {
  final String id;
  final String bookId;

  /// Stable key derived from [ReaderLocation] (page/chapter).
  final String locationKey;
  final InkTool tool;
  final int colorValue;
  final double baseWidth;
  final List<InkPoint> points;
  final DateTime createdAt;

  const InkStroke({
    required this.id,
    required this.bookId,
    required this.locationKey,
    required this.tool,
    required this.colorValue,
    required this.baseWidth,
    required this.points,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  bool get isEraser => tool == InkTool.eraser;

  InkStroke copyWith({
    String? id,
    String? bookId,
    String? locationKey,
    InkTool? tool,
    int? colorValue,
    double? baseWidth,
    List<InkPoint>? points,
    DateTime? createdAt,
  }) {
    return InkStroke(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      locationKey: locationKey ?? this.locationKey,
      tool: tool ?? this.tool,
      colorValue: colorValue ?? this.colorValue,
      baseWidth: baseWidth ?? this.baseWidth,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'locationKey': locationKey,
        'tool': tool.name,
        'colorValue': colorValue,
        'baseWidth': baseWidth,
        'points': points.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory InkStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    return InkStroke(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      locationKey: json['locationKey'] as String? ?? '',
      tool: InkTool.values.firstWhere(
        (e) => e.name == json['tool'],
        orElse: () => InkTool.pen,
      ),
      colorValue: json['colorValue'] as int? ?? 0xFF1A1A2E,
      baseWidth: (json['baseWidth'] as num?)?.toDouble() ?? 2.5,
      points: rawPoints
          .whereType<Map>()
          .map(
            (p) => InkPoint.fromJson(
              p.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String encodePoints() => jsonEncode(points.map((p) => p.toJson()).toList());

  static List<InkPoint> decodePoints(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (p) => InkPoint.fromJson(
              p.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// True when any eraser sample falls within [radius] of a stroke point.
  bool intersectsEraserPath(List<InkPoint> eraserPoints, {double radius = 18}) {
    if (points.isEmpty || eraserPoints.isEmpty) return false;
    final r2 = radius * radius;
    for (final eraser in eraserPoints) {
      for (final point in points) {
        final dx = eraser.x - point.x;
        final dy = eraser.y - point.y;
        if (dx * dx + dy * dy <= r2) return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [id];
}
