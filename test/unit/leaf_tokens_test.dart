import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/theme/leaf_tokens.dart';

void main() {
  test('LeafTokens motion durations mirror AppConstants', () {
    expect(LeafTokens.motionFast, AppConstants.animationFast);
    expect(LeafTokens.motionNormal, AppConstants.animationNormal);
    expect(LeafTokens.motionSlow, AppConstants.animationSlow);
  });

  test('LeafTokens spacing ladder is monotonic', () {
    expect(LeafTokens.spaceXs < LeafTokens.spaceSm, isTrue);
    expect(LeafTokens.spaceSm < LeafTokens.spaceMd, isTrue);
    expect(LeafTokens.spaceMd < LeafTokens.spaceLg, isTrue);
    expect(LeafTokens.spaceLg < LeafTokens.spaceXl, isTrue);
  });
}
