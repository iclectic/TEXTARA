import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/brightness_service.dart';

void main() {
  group('NoOpBrightnessService', () {
    test('records applied brightness and clears on reset', () async {
      final service = NoOpBrightnessService();
      await service.apply(0.42);
      expect(service.lastApplied, 0.42);

      await service.reset();
      expect(service.lastApplied, isNull);
    });
  });
}
