import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Anonymous product analytics (PostHog, EU cloud).
///
/// What we send: which screen / onboarding step someone reached and which
/// button they pressed, enough to see where people drop off in onboarding,
/// on the paywall and in the first days. What we never send: names, map
/// titles, questions, entries, notes or anything typed.
///
/// Pixi shares the PostHog project with Sprout. Every event carries the super
/// property `app: pixi`, so dashboards filter on it.
///
/// No person profiles, no session replay, no IDFA / ATT. Debug builds send
/// nothing (kDebugMode), so testing never pollutes the funnels.
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  /// PostHog project API key (public, write-only). Override per build with
  /// `--dart-define=POSTHOG_KEY=phc_...`.
  static const String _key = String.fromEnvironment(
    'POSTHOG_KEY',
    defaultValue: 'phc_uuJbfo64o9543TNmg7rXgjLNuUkNCwsWriyEgPMzMuBA',
  );
  static const String _host = 'https://eu.i.posthog.com';

  /// One-off verification run from a debug build:
  /// `--dart-define=POSTHOG_DEBUG_SEND=true` (events get `debug_build: true`).
  static const bool _debugSend = bool.fromEnvironment('POSTHOG_DEBUG_SEND');

  bool _ready = false;

  /// Debug-only diagnostics, shown on the paywall in debug builds.
  static final ValueNotifier<String> debugStatus = ValueNotifier('not started');
  int _sent = 0;
  final Set<String> _once = {};

  Future<void> init() async {
    if (_key.isEmpty) {
      debugStatus.value = 'no key';
      return;
    }
    if (kDebugMode && !_debugSend) {
      debugStatus.value = 'disabled in debug builds';
      return;
    }
    try {
      final config = PostHogConfig(_key)
        ..host = _host
        ..personProfiles = PostHogPersonProfiles.never
        ..captureApplicationLifecycleEvents = true
        ..sessionReplay = false
        ..debug = kDebugMode;
      await Posthog().setup(config);
      await Posthog().register('app', 'pixi');
      if (kDebugMode) await Posthog().register('debug_build', true);
      _ready = true;
      debugStatus.value = 'setup ok';
    } catch (e) {
      debugStatus.value = 'setup failed: $e';
      debugPrint('Analytics init failed: $e');
    }
  }

  /// Fire-and-forget event.
  void track(String event, [Map<String, Object>? props]) {
    if (!_ready) return;
    Posthog().capture(eventName: event, properties: props).then((_) {
      _sent++;
      debugStatus.value = 'captured $_sent (last: $event)';
    }).catchError((Object e) {
      debugStatus.value = 'capture failed: $e';
      debugPrint('Analytics capture failed: $e');
    });
  }

  /// Like [track], but only once per app run for the given key (e.g. a
  /// section of the paywall scrolled into view).
  void trackOnce(String key, String event, [Map<String, Object>? props]) {
    if (!_once.add(key)) return;
    track(event, props);
  }

  void screen(String name) {
    if (!_ready) return;
    Posthog().screen(screenName: name).catchError((Object e) {
      debugPrint('Analytics screen failed: $e');
    });
  }
}
