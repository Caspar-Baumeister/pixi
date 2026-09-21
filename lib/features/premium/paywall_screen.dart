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
import '../../widgets/ui.dart';

enum PaywallReason { maps, stats, settings }

/// Two plans (lifetime + yearly), no monthly subscription. Prices come from
/// the store via RevenueCat; static strings are only a fallback.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason = PaywallReason.settings});
  final PaywallReason reason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package>? _packages;
  PackageType _selected = PackageType.lifetime;
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
    final life = _pkg(PackageType.lifetime);
    final year = _pkg(PackageType.annual);
    return Scaffold(
      backgroundColor: PixiColors.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 0.9,
                    colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
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
                      const Center(child: GlowingCat(color: accent, size: 170)),
                      Text(s.t('paywall_title'), style: PixiText.title(size: 30)),
                      const SizedBox(height: 6),
                      Text(
                        widget.reason == PaywallReason.maps
                            ? '${s.t('free_limit_title')} ${s.t('free_limit_sub')}'
                            : s.t('paywall_sub'),
                        style: PixiText.body1(color: PixiColors.muted),
                      ),
                      const SizedBox(height: 22),
                      _Feature(icon: Icons.grid_view_rounded, text: s.t('feat_maps')),
                      _Feature(icon: Icons.insights_rounded, text: s.t('feat_stats')),
                      _Feature(icon: Icons.pets_rounded, text: s.t('feat_support')),
                      const SizedBox(height: 22),
                      _PlanTile(
                        title: s.t('plan_life'),
                        price: life?.storeProduct.priceString ?? s.t('plan_life_price'),
                        sub: s.t('plan_life_sub'),
                        selected: _selected == PackageType.lifetime,
                        onTap: () => setState(() => _selected = PackageType.lifetime),
                        badge: s.isDe ? 'Beliebt' : 'Popular',
                      ),
                      const SizedBox(height: 10),
                      _PlanTile(
                        title: s.t('plan_year'),
                        price: year?.storeProduct.priceString ?? s.t('plan_year_price'),
                        sub: s.t('plan_year_sub'),
                        selected: _selected == PackageType.annual,
                        onTap: () => setState(() => _selected = PackageType.annual),
                      ),
                      const SizedBox(height: 14),
                      Text(s.t('sub_disclosure'), style: PixiText.label(size: 11), textAlign: TextAlign.center),
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
                      PrimaryButton(label: s.t('buy'), loading: _busy, onPressed: _buy),
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({
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
