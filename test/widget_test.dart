import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/theme/leaf_theme.dart';
import 'package:textara/domain/entities/app_theme.dart';
import 'package:textara/presentation/widgets/library/library_empty_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'first_run': false});
  });

  testWidgets('MaterialApp with LeafTheme mounts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: LeafTheme.fromAppTheme(BuiltInThemes.porcelain),
          home: Scaffold(body: LibraryEmptyState(onImport: () {})),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
  });
}
