import 'package:flutter/foundation.dart';

import 'screenshot_mode.dart';

/// Dev mode for local testing. Only exists in debug builds: in release
/// builds [kDevFlow] is a compile-time false and everything below is dead
/// code.
///
/// With the dev flow on, every debug launch walks the full first-run path:
/// onboarding, then the paywall with a "Skip (debug)" button. The stored
/// "onboarding done" flag is ignored, not deleted (the onboarding adds its
/// map to the existing data). Turn it off with `--dart-define=DEV_FLOW=0` to
/// launch like a real user. Screenshot mode never uses it.
const bool kDevFlow = kDebugMode &&
    !kScreenshotMode &&
    String.fromEnvironment('DEV_FLOW', defaultValue: '1') != '0';

class DevFlow {
  DevFlow._();

  /// Onboarding finished during this run.
  static final ValueNotifier<bool> onboardingDone = ValueNotifier(false);

  /// "Skip (debug)" tapped on the paywall: the app opens until the next
  /// launch.
  static final ValueNotifier<bool> paywallSkipped = ValueNotifier(false);
}
