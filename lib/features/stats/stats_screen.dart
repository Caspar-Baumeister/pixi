import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/stats.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/links.dart';
import '../../widgets/patterns.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';
import '../premium/paywall_screen.dart';

/// Statistics + correlations for one map (Premium).
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key, required this.mapId});
  final String mapId;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final year = ref.watch(selectedYearProvider);
    final premium = data.settings.premium;
    final map = data.maps.where((m) => m.id == widget.mapId).firstOrNull;
    if (map == null) return const Scaffold(body: SizedBox.shrink());
    final entries = data.entriesFor(map.id);
    final count = entries.keys.where((k) => k.startsWith('$year-')).length;
    final today = DateTime.now();
    final monthOf = year == today.year ? today.month : 12;
    final month = monthColors(map, entries, year, monthOf);
    final links = computeLinks(data.maps, {for (final m in data.maps) m.id: data.entriesFor(m.id)}).take(10).toList();

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ---- what belongs together: the 10 strongest links across all maps
        Text(s.t('links_title'), style: PixiText.title(size: 22)),
        const SizedBox(height: 4),
        Text(s.t('links_sub'), style: PixiText.label()),
        const SizedBox(height: 10),
        PaperCard(
          glowColor: map.baseColor,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: links.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    data.maps.length < 2 ? s.t('corr_need_two') : s.t('links_none'),
                    style: PixiText.body1(color: PixiColors.muted),
                  ),
                )
              : Column(children: [for (final l in links) LinkRow(link: l)]),
        ),
        const SizedBox(height: 24),
        Text(s.r(map.title), style: PixiText.title(size: 22)),
        const SizedBox(height: 10),
        if (count < 3)
          PaperCard(
            child: Row(
              children: [
                PixiCat(size: 56, anim: CatAnims.forMap(map), animate: false),
                const SizedBox(width: 12),
                Expanded(child: Text(s.t('not_enough_data'), style: PixiText.body1())),
              ],
            ),
          )
        else ...[
          MonthShiftCard(map: map, month: month),
          const SizedBox(height: 12),
          WeekdayCard(map: map, entries: entries, year: year),
          const SizedBox(height: 12),
          YearColorsCard(map: map, entries: entries, year: year),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: PixiColors.paper,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(s.t('stats_title'), style: PixiText.title(size: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GlowBody(
        color: map.baseColor,
        child: premium
          ? content
          : Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Opacity(opacity: 0.55, child: content),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: PaperCard(
                      glowColor: map.baseColor,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PixiCat(size: 120),
                          const SizedBox(height: 8),
                          Text(s.t('stats_locked_title'), style: PixiText.title(size: 22), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(s.t('stats_locked_sub'), style: PixiText.body1(color: PixiColors.muted), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: s.t('premium'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PaywallScreen(reason: PaywallReason.stats)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
