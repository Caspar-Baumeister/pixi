import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/dev_flow.dart';
import '../../core/links.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/templates.dart';
import '../../services/analytics.dart';
import '../../services/premium_service.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';
import 'paywall_story.dart';

enum PaywallReason { maps, stats, settings }

/// The one paywall.
///
/// Hard ([hard] = true): shown by the app root after the onboarding and on
/// every launch without Premium. No close button; Pixi Premium *is* the app.
/// Soft: people who installed the free 1.0.0 still reach it from the map
/// limit, the statistics and the settings, with a close button.
///
/// Two plans: monthly with a 7-day free trial (default) and lifetime. Real
/// prices from StoreKit, trial terms next to the button, Restore, Terms
/// (Apple EULA) and Privacy.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    this.reason = PaywallReason.settings,
    this.hard = false,
    this.source,
  });

  final PaywallReason reason;
  final bool hard;

  /// Analytics source; defaults to the [reason].
  final String? source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> with WidgetsBindingObserver {
  List<Package>? _packages;
  Package? _selected;
  bool _busy = false;

  /// 'load' or 'config', mapped to text in [_errorText].
  String? _error;
  int _attempt = 0;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Analytics.instance.track('paywall_viewed', {
      'source': widget.source ?? widget.reason.name,
      'hard': widget.hard,
    });
    _load();
  }

  @override
  void dispose() {
    _retry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in the app (e.g. after fixing the connection): try again.
    if (state == AppLifecycleState.resumed && (_packages?.isEmpty ?? false)) {
      _load(silent: true);
    }
  }

  String _plan(Package? p) => switch (p?.packageType) {
        PackageType.monthly => 'monthly',
        PackageType.lifetime => 'lifetime',
        _ => 'other',
      };

  /// Loads the plans. StoreKit can fail for a moment, so we retry with a
  /// growing delay and only show the error box after the quick retries.
  /// While visible the paywall keeps retrying, it is never a dead end.
  Future<void> _load({bool silent = false}) async {
    _retry?.cancel();
    if (!silent) {
      setState(() {
        _error = null;
        _packages = null;
      });
    }
    final pk = (await PremiumService.instance.packages())
        .where((p) => p.packageType == PackageType.monthly || p.packageType == PackageType.lifetime)
        .toList();
    if (!mounted) return;
    _attempt++;
    if (pk.isNotEmpty) {
      if (_attempt > 1) Analytics.instance.track('paywall_load_recovered', {'attempt': _attempt});
      _attempt = 0;
      setState(() {
        _packages = pk;
        _selected = pk.first;
        _error = null;
      });
      return;
    }
    Analytics.instance.track('paywall_load_failed', {
      'attempt': _attempt,
      'reason': PremiumService.instance.lastError ?? 'unknown',
    });
    const quick = [2, 4, 8];
    final delay = _attempt <= quick.length ? quick[_attempt - 1] : 30;
    _retry = Timer(Duration(seconds: delay), () {
      if (mounted) _load(silent: true);
    });
    if (_attempt <= quick.length && _packages == null) return;
    setState(() {
      _packages = const [];
      _selected = null;
      _error = PremiumService.instance.isConfigured ? 'load' : 'config';
    });
  }

  void _granted() {
    ref.read(appProvider.notifier).updateSettings((s) => s.copyWith(premium: true));
    // The hard paywall disappears on its own (the app root rebuilds).
    if (!widget.hard && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).t('premium_active'))));
      Navigator.of(context).pop();
    }
  }

  Future<void> _buy() async {
    final p = _selected;
    if (p == null || _busy) return;
    setState(() => _busy = true);
    Analytics.instance.track('purchase_started', {'plan': _plan(p)});
    final ok = await PremiumService.instance.purchase(p);
    Analytics.instance.track(ok ? 'purchase_completed' : 'purchase_not_completed', {'plan': _plan(p)});
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _granted();
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await PremiumService.instance.restore();
    Analytics.instance.track('restore_tapped', {'restored': ok});
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _granted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).t('pw_no_purchase'))));
    }
  }

  void _select(Package p) {
    HapticFeedback.selectionClick();
    Analytics.instance.track('paywall_plan_selected', {'plan': _plan(p)});
    setState(() => _selected = p);
  }

  Package? _find(PackageType t) => _packages?.where((p) => p.packageType == t).firstOrNull;

  bool get _selectedHasTrial =>
      _selected?.packageType == PackageType.monthly && PremiumService.freeTrial(_selected) != null;

  String _cta(S s) {
    final p = _selected;
    if (p == null) return s.t('pw_cta_continue');
    if (_selectedHasTrial) return s.t('pw_cta_trial');
    if (p.packageType == PackageType.lifetime) return s.t('pw_cta_lifetime');
    return s.t('pw_cta_subscribe');
  }

  String _legal(S s) {
    final p = _selected;
    if (p == null) return '';
    final price = p.storeProduct.priceString;
    final key = _selectedHasTrial
        ? 'pw_legal_trial'
        : p.packageType == PackageType.lifetime
            ? 'pw_legal_lifetime'
            : 'pw_legal_monthly';
    return s.t(key).replaceAll('{price}', price);
  }

  String _tagline(S s) {
    if (!widget.hard && widget.reason == PaywallReason.maps) {
      return '${s.t('free_limit_title')} ${s.t('free_limit_sub')}';
    }
    final maps = ref.read(appProvider).maps;
    if (maps.isEmpty) return s.t('pw_tagline');
    final title = s.r(maps.first.title).trim();
    if (title.isEmpty) return s.t('pw_tagline');
    return s.t('pw_tagline_map').replaceAll('{map}', title);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final maps = ref.watch(appProvider).maps;
    final accent = maps.isNotEmpty ? maps.first.baseColor : BaseColors.violet;
    final pad = MediaQuery.of(context).padding;
    final monthly = _find(PackageType.monthly);
    final lifetime = _find(PackageType.lifetime);

    final page = Scaffold(
      backgroundColor: PixiColors.paper,
      body: Stack(
        children: [
          PageGlow(color: accent),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(24, pad.top + 4, 24, 8),
                  children: [
                    GestureDetector(
                      onLongPress: kDebugMode ? PremiumService.instance.debugGrant : null,
                      child: Center(child: GlowingCat(color: accent, size: 92, catId: 'happy')),
                    ),
                    Text('Pixi Premium', textAlign: TextAlign.center, style: PixiText.title(size: 30)),
                    const SizedBox(height: 4),
                    Text(_tagline(s),
                        textAlign: TextAlign.center, style: PixiText.body1(size: 15, color: PixiColors.muted)),
                    const SizedBox(height: 18),
                    _Benefit(icon: Icons.grid_view_rounded, color: accent, title: s.t('pw_b_maps_t'), body: s.t('pw_b_maps_b')),
                    _Benefit(icon: Icons.insights_rounded, color: accent, title: s.t('pw_b_stats_t'), body: s.t('pw_b_stats_b')),
                    _Benefit(icon: Icons.donut_large_rounded, color: accent, title: s.t('pw_b_wheel_t'), body: s.t('pw_b_wheel_b')),
                    _Benefit(icon: Icons.wb_twilight_rounded, color: accent, title: s.t('pw_b_morning_t'), body: s.t('pw_b_morning_b')),
                    const SizedBox(height: 8),
                    if (_packages == null && _error == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator(color: PixiColors.ink, strokeWidth: 2.4)),
                      )
                    else if (_error != null)
                      _ErrorBox(
                        message: s.t(_error == 'config' ? 'pw_error_config' : 'pw_error_load'),
                        retry: s.t('pw_try_again'),
                        onRetry: _load,
                      )
                    else ...[
                      if (monthly != null)
                        _PlanCard(
                          title: s.t('pw_plan_monthly'),
                          badge: PremiumService.freeTrial(monthly) != null ? s.t('pw_badge_trial') : null,
                          price: s.t('pw_price_month').replaceAll('{price}', monthly.storeProduct.priceString),
                          sub: s.t(PremiumService.freeTrial(monthly) != null ? 'pw_sub_trial' : 'pw_sub_monthly'),
                          selected: _selected == monthly,
                          accent: accent,
                          onTap: () => _select(monthly),
                        ),
                      if (lifetime != null) ...[
                        const SizedBox(height: 10),
                        _PlanCard(
                          title: s.t('pw_plan_lifetime'),
                          badge: s.t('pw_badge_best'),
                          price: s.t('pw_price_once').replaceAll('{price}', lifetime.storeProduct.priceString),
                          sub: s.t('pw_sub_lifetime'),
                          selected: _selected == lifetime,
                          accent: accent,
                          onTap: () => _select(lifetime),
                        ),
                      ],
                    ],
                    const SizedBox(height: 18),
                    const SocialProof(),
                    const SizedBox(height: 30),
                    ...paywallStory(context),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Sticky footer: one CTA and the legal lines.
              Container(
                padding: EdgeInsets.fromLTRB(24, 12, 24, pad.bottom + 10),
                decoration: const BoxDecoration(
                  color: PixiColors.paper,
                  border: Border(top: BorderSide(color: PixiColors.line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      label: _cta(s),
                      loading: _busy,
                      onPressed: _selected == null ? null : _buy,
                    ),
                    const SizedBox(height: 8),
                    Text(_legal(s),
                        textAlign: TextAlign.center, style: PixiText.label(size: 11, color: PixiColors.muted)),
                    const SizedBox(height: 2),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Link(label: s.t('pw_restore'), onTap: _restore),
                        Text('·', style: PixiText.label()),
                        _Link(label: s.t('terms'), onTap: () => _open(Links.terms)),
                        Text('·', style: PixiText.label()),
                        _Link(label: s.t('privacy'), onTap: () => _open(Links.privacy)),
                      ],
                    ),
                    if (kDebugMode)
                      ValueListenableBuilder<String>(
                        valueListenable: Analytics.debugStatus,
                        builder: (context, v, _) =>
                            Text('analytics: $v', style: const TextStyle(fontSize: 10, color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.hard)
            Positioned(
              top: pad.top + 8,
              right: 16,
              child: CircleIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  Analytics.instance.track('paywall_closed', {'source': widget.source ?? widget.reason.name});
                  Navigator.of(context).pop();
                },
              ),
            ),
          if (kDevFlow && widget.hard)
            Positioned(
              top: pad.top + 4,
              right: 12,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => DevFlow.paywallSkipped.value = true,
                child: const Text('Skip (debug)'),
              ),
            ),
        ],
      ),
    );
    // The hard paywall cannot be swiped away.
    return widget.hard ? PopScope(canPop: false, child: page) : page;
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.color, required this.title, required this.body});
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: PixiColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PixiText.body1(size: 15, color: PixiColors.ink).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(body, style: PixiText.label(size: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.sub,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String sub;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: PixiColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? PixiColors.ink : PixiColors.line, width: selected ? 2 : 1),
          boxShadow: [
            if (selected) BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 28),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? PixiColors.ink : PixiColors.faint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: PixiText.title(size: 18))),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: PixiColors.ink, borderRadius: BorderRadius.circular(999)),
                          child: Text(badge!, style: PixiText.label(size: 10, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(price, style: PixiText.body1(size: 15, color: PixiColors.ink).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(sub, style: PixiText.label(size: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social proof, version 1 (no reviews yet): three researched numbers.
/// Version 2 replaces it with real App Store reviews once there are some.
class SocialProof extends StatelessWidget {
  const SocialProof({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget tile(String n, String t) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            decoration: BoxDecoration(
              color: PixiColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PixiColors.line),
            ),
            child: Column(
              children: [
                Text(n, style: PixiText.title(size: 28)),
                const SizedBox(height: 2),
                Text(t, textAlign: TextAlign.center, style: PixiText.label(size: 11.5, color: PixiColors.inkSoft)),
              ],
            ),
          ),
        );
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(s.t('pw_proof_1_n'), s.t('pw_proof_1_t')),
              const SizedBox(width: 8),
              tile(s.t('pw_proof_2_n'), s.t('pw_proof_2_t')),
              const SizedBox(width: 8),
              tile(s.t('pw_proof_3_n'), s.t('pw_proof_3_t')),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(s.t('pw_proof_src'), style: PixiText.label(size: 10.5).copyWith(fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.retry, required this.onRetry});
  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PixiColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PixiColors.line),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: PixiText.body1(size: 14)),
          // Tiny technical reason: lets a user screenshot tell us what the store said.
          if (PremiumService.instance.lastError case final reason?) ...[
            const SizedBox(height: 6),
            Text(reason.split(':').first, textAlign: TextAlign.center, style: PixiText.label(size: 10.5)),
          ],
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: Text(retry, style: PixiText.label(color: PixiColors.ink))),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: PixiText.label(size: 12, color: PixiColors.inkSoft)),
      );
}
