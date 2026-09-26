import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/screenshot_mode.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'features/checkin/checkin_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/premium_service.dart';
import 'widgets/pixi_cat.dart';
import 'widgets/splash.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class PixiApp extends ConsumerStatefulWidget {
  const PixiApp({super.key});

  @override
  ConsumerState<PixiApp> createState() => _PixiAppState();
}

class _PixiAppState extends ConsumerState<PixiApp> {
  /// Splash on every cold start (lies over the app, which builds underneath).
  bool _splash = true;

  void _syncPremium() {
    final v = PremiumService.instance.pro.value;
    if (v == null || !PremiumService.instance.isConfigured) return;
    final cur = ref.read(settingsProvider).premium;
    // In debug builds a manual test toggle may grant premium; never revoke it there.
    if (cur != v && (v || !kDebugMode)) {
      ref.read(appProvider.notifier).updateSettings((s) => s.copyWith(premium: v));
    }
  }

  @override
  void initState() {
    super.initState();
    PremiumService.instance.pro.addListener(_syncPremium);
    PremiumService.instance.init();
    // Tapping the morning notification opens the questions directly, both
    // while the app runs and when the tap starts the app.
    NotificationService.instance.onTap = _openCheckin;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await NotificationService.instance.launchedFromNotification()) _openCheckin();
    });
  }

  void _openCheckin() {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckin());
      return;
    }
    final data = ref.read(appProvider);
    if (!data.settings.onboardingDone || data.maps.isEmpty) return;
    nav.popUntil((r) => r.isFirst);
    nav.push(MaterialPageRoute(
      settings: const RouteSettings(name: 'checkin'),
      builder: (_) => const CheckinScreen(),
    ));
    // skip the splash, the questions are what the user came for
    if (_splash && mounted) setState(() => _splash = false);
  }

  @override
  void dispose() {
    PremiumService.instance.pro.removeListener(_syncPremium);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingDone = ref.watch(settingsProvider.select((s) => s.onboardingDone));
    return MaterialApp(
      title: 'Pixi',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: buildPixiTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de'), Locale('en')],
      locale: ref.watch(localeOverrideProvider),
      builder: (context, child) {
        PixiCat.precache(context);
        // Always a Stack, so the navigator below keeps its state when the
        // splash goes away.
        final c = Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            if (_splash) Positioned.fill(child: PixiSplash(onDone: () => setState(() => _splash = false))),
          ],
        );
        return kScreenshotMode ? RepaintBoundary(key: shotBoundaryKey, child: c) : c;
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }
}
