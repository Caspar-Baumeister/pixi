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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class PixiApp extends ConsumerStatefulWidget {
  const PixiApp({super.key});

  @override
  ConsumerState<PixiApp> createState() => _PixiAppState();
}

class _PixiAppState extends ConsumerState<PixiApp> {
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
    // Tapping the morning notification opens the check-in directly.
    NotificationService.instance.onTap = () {
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;
      final data = ref.read(appProvider);
      if (!data.settings.onboardingDone || data.maps.isEmpty) return;
      nav.push(MaterialPageRoute(builder: (_) => const CheckinScreen()));
    };
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
        final c = child ?? const SizedBox.shrink();
        return kScreenshotMode ? RepaintBoundary(key: shotBoundaryKey, child: c) : c;
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }
}
