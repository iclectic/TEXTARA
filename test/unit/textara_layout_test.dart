import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/layout/textara_layout.dart';

void main() {
  test('tablet layout uses the shortest side', () {
    expect(isTextaraTablet(const Size(800, 1200)), isTrue);
    expect(isTextaraTablet(const Size(600, 900)), isTrue);
    expect(isTextaraTablet(const Size(599, 900)), isFalse);
    expect(isTextaraTablet(const Size(1200, 500)), isFalse);
  });
}
