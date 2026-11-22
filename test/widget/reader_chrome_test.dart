import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/theme/leaf_theme.dart';
import 'package:textara/domain/entities/app_theme.dart';
import 'package:textara/presentation/widgets/reader/reader_app_bar.dart';
import 'package:textara/presentation/widgets/reader/reader_bottom_bar.dart';

void main() {
  testWidgets('ReaderBottomBar shows Chapter X of Y label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LeafTheme.fromAppTheme(BuiltInThemes.porcelain),
        home: const Scaffold(
          body: ReaderBottomBar(
            positionLabel: 'Chapter 2 of 9',
            chapterTitle: 'Second',
            progress: 0.2,
            minutesLeft: 3,
            onToc: _noop,
            onAnnotations: _noop,
          ),
        ),
      ),
    );
    expect(find.text('Chapter 2 of 9'), findsOneWidget);
    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('ReaderAppBar exposes TTS when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LeafTheme.fromAppTheme(BuiltInThemes.porcelain),
        home: Scaffold(
          body: ReaderAppBar(
            title: 'Demo',
            onBack: _noop,
            onBookmark: _noop,
            onSettings: _noop,
            onTts: _noop,
            ttsPlaying: false,
          ),
        ),
      ),
    );
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });
}

void _noop() {}
