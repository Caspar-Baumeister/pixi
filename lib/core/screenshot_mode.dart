import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pix_map.dart';
import '../models/templates.dart';
import 'demo_data.dart';
import '../app.dart';
import '../data/providers.dart';
import '../features/checkin/checkin_screen.dart';
import '../features/circle/circle_screen.dart';
import '../features/maps/maps_screen.dart';
import '../features/maps/templates_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/stats/stats_screen.dart';

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
      training.id: DemoData.correlatedWith(moodData, mood.levels.length, training.levels.length),
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


// ---------------------------------------------------------------------------
// Remote control for store screenshots (called via the Dart VM service
// `evaluate`, e.g. shotNav('circle'); shotCapture('en_3_circle')).
// ---------------------------------------------------------------------------

final GlobalKey shotBoundaryKey = GlobalKey();
const String kShotDir = '/Users/casparbaumeister/Documents/projekte/pixi/pixi_app/_shots/raw';

ProviderContainer _container() => ProviderScope.containerOf(rootNavigatorKey.currentContext!);

String shotNav(String where, [String arg = '']) {
  final nav = rootNavigatorKey.currentState!;
  final c = _container();
  final maps = c.read(appProvider).maps;
  String mapId(String t) => maps.firstWhere((m) => m.templateId == t, orElse: () => maps.first).id;
  void push(Widget w) => nav.push(MaterialPageRoute(builder: (_) => w));
  nav.popUntil((r) => r.isFirst);
  switch (where) {
    case 'home':
      final i = maps.indexWhere((m) => m.templateId == (arg.isEmpty ? 'mood' : arg));
      c.read(selectedMapIndexProvider.notifier).state = i < 0 ? 0 : i;
      break;
    case 'checkin':
      push(const CheckinScreen());
      break;
    case 'circle':
      push(CircleScreen(mapId: mapId(arg.isEmpty ? 'mood' : arg)));
      break;
    case 'stats':
      push(StatsScreen(mapId: mapId(arg.isEmpty ? 'mood' : arg)));
      break;
    case 'maps':
      push(const MapsScreen());
      break;
    case 'templates':
      push(const TemplatesScreen());
      break;
    case 'paywall':
      push(const PaywallScreen());
      break;
    case 'onboarding':
      push(OnboardingScreen(startStep: arg.isEmpty ? null : arg));
      break;
    case 'de':
    case 'en':
      c.read(localeOverrideProvider.notifier).state = Locale(where);
      break;
  }
  return 'ok $where';
}

Future<String> shotCapture(String name, [double pixelRatio = 3]) async {
  final boundary = shotBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory(kShotDir)..createSync(recursive: true);
  final f = File('${dir.path}/$name.png');
  await f.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  return '${f.path} ${image.width}x${image.height}';
}

/// Scroll the first scrollable on screen (e.g. stats) by [dy] logical pixels.
String shotScroll(double dy) {
  void visit(Element e) {
    if (e.widget is Scrollable) {
      final st = (e as StatefulElement).state as ScrollableState;
      st.position.jumpTo((st.position.pixels + dy).clamp(0, st.position.maxScrollExtent));
      return;
    }
    e.visitChildren(visit);
  }
  rootNavigatorKey.currentContext!.visitChildElements(visit);
  return 'scrolled';
}


/// Dev helper (screenshot mode only): append a base64 chunk to a file under
/// the project's _shots/in folder. Used to bring generated sprite sheets in.
String shotWrite(String name, String b64, [bool first = false]) {
  if (!kScreenshotMode) return 'off';
  final dir = Directory('${kShotDir.replaceAll('/raw', '')}/in')..createSync(recursive: true);
  final f = File('${dir.path}/$name');
  f.writeAsBytesSync(base64Decode(b64), mode: first ? FileMode.write : FileMode.append, flush: true);
  return 'ok ${f.lengthSync()}';
}
