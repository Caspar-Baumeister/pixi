import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/stats.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../widgets/links.dart';
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
  String? _otherId;

  String _fmt(S s, double v) => v.toStringAsFixed(1).replaceAll('.', s.isDe ? ',' : '.');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final year = ref.watch(selectedYearProvider);
    final premium = data.settings.premium;
    final map = data.maps.where((m) => m.id == widget.mapId).firstOrNull;
    if (map == null) return const Scaffold(body: SizedBox.shrink());
    final entries = data.entriesFor(map.id);
    final stats = computeStats(map, entries, year);
    final today = DateTime.now();
    final monthOf = year == today.year ? today.month : 12;
    final month = monthColors(map, entries, year, monthOf);
    final others = data.maps.where((m) => m.id != map.id).toList();
    final other = others.where((m) => m.id == _otherId).firstOrNull ?? others.firstOrNull;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (stats.count < 3)
          PaperCard(
            child: Row(
              children: [
                const PixiCat(size: 56),
                const SizedBox(width: 12),
                Expanded(child: Text(s.t('not_enough_data'), style: PixiText.body1())),
              ],
            ),
          ),
        if (stats.count >= 3) ...[
          _MonthCard(map: map, month: month, monthName: s.monthsLong[month.month - 1]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: s.t('average'),
                  value: stats.average == null ? '–' : _fmt(s, stats.average!),
                  sub: stats.average == null ? '' : s.r(map.levels[stats.average!.round().clamp(0, map.levels.length - 1)].label),
                  color: map.baseColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(label: s.t('days_filled'), value: '${stats.count}', sub: '${s.t('streak')} ${stats.streak}', color: map.baseColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: s.t('best_month'),
                  value: stats.bestMonth == null ? '–' : s.monthsShort[stats.bestMonth!],
                  sub: stats.bestMonth == null ? '' : 'Ø ${_fmt(s, stats.monthAverages[stats.bestMonth!]!)}',
                  color: map.baseColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  label: s.t('best_weekday'),
                  value: stats.bestWeekday == null ? '–' : s.weekdaysShort[stats.bestWeekday!],
                  sub: stats.worstWeekday == null ? '' : '${s.t('weakest_weekday')}: ${s.weekdaysShort[stats.worstWeekday!]}',
                  color: map.baseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('per_month'), style: PixiText.label()),
                const SizedBox(height: 14),
                _Bars(
                  values: stats.monthAverages,
                  maxValue: max(1, map.levels.length - 1).toDouble(),
                  labels: s.monthLetters,
                  map: map,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isDe ? 'Pro Wochentag' : 'Per weekday', style: PixiText.label()),
                const SizedBox(height: 14),
                _Bars(
                  values: stats.weekdayAverages,
                  maxValue: max(1, map.levels.length - 1).toDouble(),
                  labels: s.weekdaysShort,
                  map: map,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('distribution'), style: PixiText.label()),
                const SizedBox(height: 12),
                for (var i = map.levels.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: map.levels[i].color, borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 78, child: Text(s.r(map.levels[i].label), style: PixiText.label(size: 12, color: PixiColors.ink), overflow: TextOverflow.ellipsis)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stats.count == 0 ? 0 : stats.distribution[i] / stats.count,
                              minHeight: 8,
                              backgroundColor: PixiColors.paperDark,
                              color: map.levels[i].color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 30, child: Text('${stats.distribution[i]}', textAlign: TextAlign.right, style: PixiText.label(size: 12))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(s.t('links_title'), style: PixiText.title(size: 22)),
        const SizedBox(height: 4),
        Text(s.t('links_sub'), style: PixiText.label()),
        const SizedBox(height: 10),
        Builder(builder: (context) {
          final links = computeLinks(data.maps, {for (final m in data.maps) m.id: data.entriesFor(m.id)}).take(10).toList();
          return PaperCard(
            glowColor: map.baseColor,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: links.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(s.t('links_none'), style: PixiText.body1(color: PixiColors.muted)),
                  )
                : Column(children: [for (final l in links) LinkRow(link: l)]),
          );
        }),
        const SizedBox(height: 24),
        Text(s.t('correlations'), style: PixiText.title(size: 22)),
        const SizedBox(height: 10),
        if (others.isEmpty)
          Text(s.t('corr_need_two'), style: PixiText.body1(color: PixiColors.muted))
        else ...[
          Text(s.t('corr_pick'), style: PixiText.label()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in others)
                ChoiceChip(
                  label: Text(s.r(m.title)),
                  selected: other?.id == m.id,
                  onSelected: (_) => setState(() => _otherId = m.id),
                  selectedColor: PixiColors.ink,
                  backgroundColor: PixiColors.card,
                  side: const BorderSide(color: PixiColors.line),
                  showCheckmark: false,
                  labelStyle: PixiText.label(size: 13, color: other?.id == m.id ? Colors.white : PixiColors.ink),
                  shape: const StadiumBorder(),
                  avatar: CircleAvatar(backgroundColor: m.baseColor, radius: 6),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (other != null) _CorrelationCard(a: other, ea: data.entriesFor(other.id), b: map, eb: entries, year: year),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: PixiColors.paper,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${s.t('stats_title')} · ${s.r(map.title)}', style: PixiText.title(size: 18)),
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

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.sub, required this.color});
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PixiText.label(size: 12)),
          const SizedBox(height: 6),
          Text(value, style: PixiText.title(size: 26)),
          if (sub.isNotEmpty) Text(sub, style: PixiText.label(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.maxValue, required this.labels, required this.map});
  final List<double?> values;
  final double maxValue;
  final List<String> labels;
  final PixMap map;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: values[i] == null
                        ? Container(
                            height: 6,
                            decoration: BoxDecoration(color: PixiColors.paperDark, borderRadius: BorderRadius.circular(3)),
                          )
                        : Container(
                            height: 8 + 86 * (values[i]! / maxValue),
                            decoration: BoxDecoration(
                              color: map.levels[values[i]!.round().clamp(0, map.levels.length - 1)].color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              boxShadow: [BoxShadow(color: map.baseColor.withValues(alpha: 0.25), blurRadius: 10)],
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final l in labels)
              Expanded(child: Text(l, textAlign: TextAlign.center, style: PixiText.label(size: 10))),
          ],
        ),
      ],
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  const _CorrelationCard({required this.a, required this.ea, required this.b, required this.eb, required this.year});
  final PixMap a;
  final Map<String, int> ea;
  final PixMap b;
  final Map<String, int> eb;
  final int year;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final links = linksBetween(a, ea, b, eb).take(4).toList();
    final shared = ea.keys.where(eb.containsKey).length;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _mini(s, a, ea)),
            const SizedBox(width: 12),
            Expanded(child: _mini(s, b, eb)),
          ],
        ),
        const SizedBox(height: 12),
        PaperCard(
          glowColor: b.baseColor,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (links.isEmpty)
                Text(shared < 10 ? s.t('corr_need_two') : s.t('corr_none'), style: PixiText.title(size: 17))
              else
                for (final l in links) LinkRow(link: l, showMaps: false),
              const SizedBox(height: 4),
              Text(s.t('corr_days').replaceAll('{n}', '$shared'), style: PixiText.label(size: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mini(S s, PixMap m, Map<String, int> e) => Container(
        decoration: BoxDecoration(
          color: PixiColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PixiColors.line),
          boxShadow: [BoxShadow(color: m.baseColor.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.r(m.title), style: PixiText.title(size: 15)),
            const SizedBox(height: 8),
            PixelGrid(map: m, entries: e, year: year, showLabels: false, gapFactor: 0.22),
          ],
        ),
      );
}


/// Colours of the current month with the change against the month before.
class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.map, required this.month, required this.monthName});
  final PixMap map;
  final MonthColors month;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final maxCount = max(1, month.counts.fold<int>(0, (a, b) => max(a, b)));
    return PaperCard(
      glowColor: map.baseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${s.t('this_month')} · $monthName', style: PixiText.label())),
              Text('${month.total} ${s.t('days_short')}', style: PixiText.label(size: 12, color: PixiColors.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.t('this_month_sub'), style: PixiText.label(size: 11, color: PixiColors.muted)),
          const SizedBox(height: 14),
          if (month.total == 0)
            Text(s.t('month_no_data'), style: PixiText.body1(color: PixiColors.muted))
          else
            for (var i = map.levels.length - 1; i >= 0; i--)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: map.levels[i].color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: PixiColors.line),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 76,
                      child: Text(s.r(map.levels[i].label),
                          style: PixiText.label(size: 12, color: PixiColors.ink), overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: PixiColors.paperDark,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (month.counts[i] / maxCount).clamp(0.0, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: map.levels[i].color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 26,
                      child: Text('${month.counts[i]}',
                          textAlign: TextAlign.right, style: PixiText.label(size: 12, color: PixiColors.ink)),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(width: 46, child: _Delta(value: month.delta(i))),
                  ],
                ),
              ),
          if (month.total > 0 && month.previousTotal > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${s.t('vs_last_month')}: ${month.previousTotal} ${s.t('days_short')}',
              style: PixiText.label(size: 11, color: PixiColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return Text('–', textAlign: TextAlign.right, style: PixiText.label(size: 12, color: PixiColors.muted));
    }
    final up = value > 0;
    final color = up ? PixiColors.ink : PixiColors.muted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: color),
        const SizedBox(width: 2),
        Text('${value.abs()}', style: PixiText.label(size: 12, color: color)),
      ],
    );
  }
}
