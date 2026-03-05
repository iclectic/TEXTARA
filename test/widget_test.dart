import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/main.dart';

void main() {
  testWidgets('Textara app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TextaraApp()),
    );
    await tester.pump();

    // App should show a loading indicator or a screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
