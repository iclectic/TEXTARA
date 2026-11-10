import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/domain/entities/ink_stroke.dart';
import 'package:textara/presentation/widgets/reader/ink_toolbar.dart';

void main() {
  testWidgets('InkToolbar switches tools and reports clear', (tester) async {
    InkTool selected = InkTool.off;
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return InkToolbar(
                tool: selected,
                onToolChanged: (tool) => setState(() => selected = tool),
                onClearPage: () => cleared = true,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Pen (stylus preferred)'));
    await tester.pump();
    expect(selected, InkTool.pen);

    await tester.tap(find.byTooltip('Eraser'));
    await tester.pump();
    expect(selected, InkTool.eraser);

    await tester.tap(find.byTooltip('Highlighter'));
    await tester.pump();
    expect(selected, InkTool.highlighter);

    await tester.tap(find.byTooltip('Ink off — scroll normally'));
    await tester.pump();
    expect(selected, InkTool.off);

    await tester.tap(find.byTooltip('Clear ink on this page'));
    await tester.pump();
    expect(cleared, isTrue);
  });
}
