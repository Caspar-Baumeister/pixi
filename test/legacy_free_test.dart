import 'package:flutter_test/flutter_test.dart';
import 'package:pixi/models/pix_map.dart';

void main() {
  test('data saved by 1.0.0 with a finished onboarding keeps the free tier', () {
    final s = Settings.fromJson({'onboardingDone': true});
    expect(s.legacyFree, isTrue);
  });

  test('fresh installs meet the hard paywall', () {
    expect(Settings.fromJson(const {}).legacyFree, isFalse);
    expect(const Settings().legacyFree, isFalse);
    // 1.1.0 saves the flag explicitly, so finishing the onboarding later
    // never turns a new user into a legacy one.
    final saved = const Settings().toJson();
    expect(Settings.fromJson({...saved, 'onboardingDone': true}).legacyFree, isFalse);
  });
}
