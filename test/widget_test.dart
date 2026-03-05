import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaf_reader/main.dart';

void main() {
  testWidgets('LeafReader app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LeafReaderApp()),
    );
    await tester.pump();

    // App should show a loading indicator or a screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
