import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/theme/leaf_theme.dart';
import 'package:textara/domain/entities/app_theme.dart';

void main() {
  testWidgets('Textara material shell builds with LeafTheme', (
    WidgetTester tester,
  ) async {
    // Avoid importing the full app graph here: it pulls pdfrx, which currently
    // fails to compile against newer Dart null-safety checking in this SDK.
    await tester.pumpWidget(
      MaterialApp(
        title: AppConstants.appName,
        theme: LeafTheme.fromAppTheme(BuiltInThemes.porcelain),
        home: const Scaffold(body: Center(child: Text('Textara'))),
      ),
    );

    expect(find.text('Textara'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
