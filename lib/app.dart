import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/dev_flow.dart';
import 'core/screenshot_mode.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'models/pix_map.dart';
import 'features/checkin/checkin_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/premium/paywall_screen.dart';
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

  /// RevenueCat gets 4 s to answer before the hard paywall may show, so
  /// paying users never see it flash (the cached premium flag covers the
  /// usual case anyway).
  bool _storeWaitOver = false;

  /// Paywall source for analytics: right after the onboarding or on a later
  /// launch without access.
  late final bool _onboardedBefore = ref.read(settingsProvider).onboardingDone;

  final _gate = Listenable.merge([
    PremiumService.instance.pro,
    PremiumService.instance.legacy,
    DevFlow.onboardingDone,
    DevFlow.paywallSkipped,
  ]);

  void _syncPremium() {
    final v = PremiumService.instance.pro.value;
    if (v == null || !PremiumService.instance.isConfigured) return;
    final cur = ref.read(settingsProvider).premium;
    // In debug builds a manual test toggle may grant premium; never revoke it there.
    if (cur != v && (v || !kDebugMode)) {
      ref.read(appProvider.notifier).updateSettings((s) => s.copyWith(premium: v));
    }
  }

  void _syncLegacy() {
    if (!PremiumService.instance.legacy.value) return;
    if (ref.read(settingsProvider).legacyFree) return;
    ref.read(appProvider.notifier).updateSettings((s) => s.copyWith(legacyFree: true));
  }

  /// Hard paywall: new users need Premium. Users of the free 1.0.0 keep the
  /// free tier; the dev flow always shows the paywall once per launch.
  bool _locked(Settings settings) {
    if (kScreenshotMode) return false;
    if (settings.premium || PremiumService.instance.isPro) return false;
    if (kDevFlow) return !DevFlow.paywallSkipped.value;
    return !(settings.legacyFree || PremiumService.instance.legacy.value);
  }

  @override
  void initState() {
    super.initState();
    PremiumService.instance.pro.addListener(_syncPremium);
    PremiumService.instance.legacy.addListener(_syncLegacy);
    PremiumService.instance.init();
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _storeWaitOver = true);
    });
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
    if (_locked(data.settings)) return;
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
    PremiumService.instance.legacy.removeListener(_syncLegacy);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
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
      home: ListenableBuilder(
        listenable: _gate,
        builder: (context, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _home(settings),
        ),
      ),
    );
  }

  Widget _home(Settings settings) {
    final onboarding = !settings.onboardingDone || (kDevFlow && !DevFlow.onboardingDone.value);
    if (onboarding) return const OnboardingScreen(key: ValueKey('onboarding'));
    if (!_locked(settings)) return const HomeScreen(key: ValueKey('home'));
    // Still waiting for RevenueCat: a quiet page instead of a paywall flash.
    if (PremiumService.instance.pro.value == null && !_storeWaitOver) {
      return const Scaffold(key: ValueKey('wait'), backgroundColor: PixiColors.paper);
    }
    return PaywallScreen(
      key: const ValueKey('paywall'),
      hard: true,
      source: _onboardedBefore ? 'launch' : 'onboarding',
    );
  }
}
