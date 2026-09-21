import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pix_map.dart';
import '../models/templates.dart';
import 'demo_data.dart';

/// Store screenshot mode: `flutter run --dart-define=SCREENSHOT=true`
/// Seeds a full, good-looking year, skips onboarding, unlocks premium and
/// shows a language switch in the settings.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT');

/// Language override (screenshot mode only). null = system language.
final localeOverrideProvider = StateProvider<Locale?>((ref) => null);

AppData buildScreenshotData() {
  final year = DateTime.now().year;
  PixMap make(String id, String t) =>
      templateById(t).toMap(id);
  final mood = make('shot-mood', 'mood');
  final sleep = make('shot-sleep', 'sleep');
  final dreams = make('shot-dreams', 'dreams');
  final training = make('shot-training', 'training');
  final moodData = DemoData.forTemplate('mood', mood.levels.length, year: year, fullYear: true);
  return AppData(
    maps: [mood, sleep, dreams, training],
    entries: {
      mood.id: moodData,
      sleep.id: DemoData.correlatedWith(moodData, mood.levels.length, sleep.levels.length),
      dreams.id: DemoData.forTemplate('dreams', dreams.levels.length, year: year, fullYear: true),
      training.id: DemoData.forTemplate('training', training.levels.length, year: year, fullYear: true),
    },
    settings: const Settings(
      name: 'Lena',
      onboardingDone: true,
      premium: true,
      remindersEnabled: true,
      feedbackAfterMapShown: true,
      feedbackAfterCheckinShown: true,
      checkinCount: 42,
    ),
  );
}
