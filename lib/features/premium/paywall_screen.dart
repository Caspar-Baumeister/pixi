import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/links.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/templates.dart';
import '../../services/premium_service.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/stats_preview.dart';
import '../../widgets/ui.dart';

enum PaywallReason { maps, stats, settings }

/// Two plans: monthly with a 3-day free trial, or pay once. Prices come from
/// the store via RevenueCat; static strings are only a fallback.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason = PaywallReason.settings});
  final PaywallReason reason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package>? _packages;
  PackageType _selected = PackageType.monthly;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PremiumService.instance.packages();
    if (mounted) setState(() => _packages = p);
  }

  Package? _pkg(PackageType t) =>
      _packages?.where((p) => p.packageType == t).firstOrNull;

  void _grant() {
    ref.read(appProvider.notifier).updateSettings((s) => s.copyWith(premium: true));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).t('premium_active'))));
    Navigator.of(context).pop();
  }

  Future<void> _buy() async {
    final pkg = _pkg(_selected);
    if (pkg == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).t('store_unavailable'))));
      return;
    }
    setState(() => _busy = true);
    final ok = await PremiumService.instance.purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _grant();
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final ok = await PremiumService.instance.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _grant();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).t('restore_none'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const accent = BaseColors.violet;
    return Scaffold(
      backgroundColor: PixiColors.paper,
      body: Stack(
        children: [
          PageGlow(color: accent),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      CircleIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    children: [
                      const Center(child: GlowingCat(color: accent, size: 130)),
                      Text(s.t('paywall_title'), style: PixiText.title(size: 30)),
                      const SizedBox(height: 6),
                      Text(
                        widget.reason == PaywallReason.maps
                            ? '${s.t('free_limit_title')} ${s.t('free_limit_sub')}'
                            : s.t('paywall_sub'),
                        style: PixiText.body1(color: PixiColors.muted),
                      ),
                      const SizedBox(height: 20),
                      Text(s.t('pw_prev_title'), style: PixiText.label()),
                      const SizedBox(height: 10),
                      const PremiumStatsPreview(),
                      const SizedBox(height: 18),
                      _Feature(icon: Icons.grid_view_rounded, text: s.t('feat_maps')),
                      _Feature(icon: Icons.insights_rounded, text: s.t('feat_stats')),
                      _Feature(icon: Icons.pets_rounded, text: s.t('feat_support')),
                      const SizedBox(height: 22),
                      PlanPicker(
                        packages: _packages,
                        selected: _selected,
                        onSelect: (p) => setState(() => _selected = p),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => launchUrl(Uri.parse(Links.terms)),
                            child: Text(s.t('terms'), style: PixiText.label(size: 12, color: PixiColors.inkSoft)),
                          ),
                          Text('·', style: PixiText.label()),
                          TextButton(
                            onPressed: () => launchUrl(Uri.parse(Links.privacy)),
                            child: Text(s.t('privacy'), style: PixiText.label(size: 12, color: PixiColors.inkSoft)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PrimaryButton(label: PlanPicker.ctaLabel(s, _packages, _selected), loading: _busy, onPressed: _buy),
                      SecondaryButton(label: s.t('restore'), onPressed: _busy ? null : _restore),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: PixiColors.paperDark, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: PixiColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: PixiText.body1(color: PixiColors.ink))),
        ],
      ),
    );
  }
}

/// Monthly (with free trial) and lifetime, plus the subscription terms.
/// Used by the paywall and the onboarding.
class PlanPicker extends StatelessWidget {
  const PlanPicker({super.key, required this.packages, required this.selected, required this.onSelect});
  final List<Package>? packages;
  final PackageType selected;
  final ValueChanged<PackageType> onSelect;

  static Package? _find(List<Package>? list, PackageType t) =>
      list?.where((p) => p.packageType == t).firstOrNull;

  /// Until the store answers we assume the trial exists (it is configured).
  static bool _hasTrial(List<Package>? list) {
    final m = _find(list, PackageType.monthly);
    return m == null || PremiumService.freeTrial(m) != null;
  }

  static String monthlyPrice(S s, List<Package>? list) =>
      _find(list, PackageType.monthly)?.storeProduct.priceString ?? s.t('plan_month_price');

  /// "Kostenlos testen" for the monthly plan, "Für immer freischalten" for lifetime.
  static String ctaLabel(S s, List<Package>? list, PackageType selected) {
    if (selected == PackageType.lifetime) return s.t('cta_life');
    return _hasTrial(list) ? s.t('cta_trial') : s.t('buy');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final life = _find(packages, PackageType.lifetime);
    final trial = _hasTrial(packages);
    final price = monthlyPrice(s, packages);
    return Column(
      children: [
        PlanTile(
          title: s.t('plan_month'),
          price: price,
          sub: (trial ? s.t('plan_month_sub') : s.t('plan_month_sub_notrial')).replaceAll('{price}', price),
          selected: selected == PackageType.monthly,
          onTap: () => onSelect(PackageType.monthly),
          badge: trial ? s.t('plan_trial_badge') : null,
        ),
        const SizedBox(height: 10),
        PlanTile(
          title: s.t('plan_life'),
          price: life?.storeProduct.priceString ?? s.t('plan_life_price'),
          sub: s.t('plan_life_sub'),
          selected: selected == PackageType.lifetime,
          onTap: () => onSelect(PackageType.lifetime),
        ),
        const SizedBox(height: 12),
        Text(
          s.t('sub_disclosure').replaceAll('{price}', price),
          style: PixiText.label(size: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// One selectable plan row.
class PlanTile extends StatelessWidget {
  const PlanTile({
    super.key,
    required this.title,
    required this.price,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final String title;
  final String price;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PixiColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? PixiColors.ink : PixiColors.line, width: selected ? 1.8 : 1),
          boxShadow: [
            if (selected) BoxShadow(color: BaseColors.violet.withValues(alpha: 0.25), blurRadius: 30),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: PixiText.title(size: 18)),
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
                  const SizedBox(height: 2),
                  Text(sub, style: PixiText.label(size: 12)),
                ],
              ),
            ),
            Text(price, style: PixiText.title(size: 20)),
          ],
        ),
      ),
    );
  }
}
