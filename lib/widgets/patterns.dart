import 'dart:math';

import 'package:flutter/material.dart';

import '../core/stats.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/pix_map.dart';
import 'ui.dart';

/// "5 Tage mehr „Albtraum“, 2 Tage weniger „Romantisch“ als im August."
String monthShiftSentence(S s, PixMap map, MonthColors m, {int max = 2}) {
  final prevName = s.monthsLong[(m.month + 10) % 12];
  final shifts = monthShifts(m).take(max).toList();
  if (shifts.isEmpty) return s.t('pat_same').replaceAll('{m}', prevName);
  final parts = [
    for (final sh in shifts)
      s
          .t(sh.delta > 0
              ? (sh.delta.abs() == 1 ? 'pat_more1' : 'pat_more')
              : (sh.delta.abs() == 1 ? 'pat_less1' : 'pat_less'))
          .replaceAll('{n}', '${sh.delta.abs()}')
          .replaceAll('{l}', s.r(map.levels[sh.level].label)),
  ];
  return '${parts.join(', ')} ${s.t('pat_than').replaceAll('{m}', prevName)}';
}

/// "An Montagen ist „Grau“ besonders oft aufgetreten."
String weekdaySentence(S s, PixMap map, WeekdayStandout w) => s
    .t('pat_week_line')
    .replaceAll('{wd}', s.weekdaysPlural[w.weekday])
    .replaceAll('{l}', s.r(map.levels[w.level].label));

class _Chip extends StatelessWidget {
  const _Chip({required this.color, this.size = 14});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)],
        ),
      );
}

/// Which colours showed up how often this month, and the change against the
/// month before. Counts of days only, never averages.
class MonthShiftCard extends StatelessWidget {
  const MonthShiftCard({super.key, required this.map, required this.month, this.compact = false});
  final PixMap map;
  final MonthColors month;

  /// Compact: sentence plus the three biggest movers, no card around it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final maxCount = max(1, month.counts.fold<int>(0, (a, b) => max(a, b)));
    final monthName = s.monthsLong[month.month - 1];
    final order = compact
        ? monthShifts(month).take(3).map((e) => e.level).toList()
        : [for (var i = map.levels.length - 1; i >= 0; i--) i];

    Widget row(int i) => Padding(
          padding: EdgeInsets.only(bottom: compact ? 8 : 10),
          child: Row(
            children: [
              _Chip(color: map.levels[i].color),
              const SizedBox(width: 10),
              SizedBox(
                width: compact ? 92 : 84,
                child: Text(s.r(map.levels[i].label),
                    style: PixiText.label(size: 12, color: PixiColors.ink), overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(color: PixiColors.paperDark, borderRadius: BorderRadius.circular(5)),
                    ),
                    FractionallySizedBox(
                      widthFactor: (month.counts[i] / maxCount).clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration:
                            BoxDecoration(color: map.levels[i].color, borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Text(
                  '${month.counts[i]} ${month.counts[i] == 1 ? s.t('day_short1') : s.t('days_short')}',
                  textAlign: TextAlign.right,
                  style: PixiText.label(size: 11.5, color: PixiColors.ink),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(width: 34, child: _Delta(value: month.delta(i))),
            ],
          ),
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text('${s.t('this_month')} · $monthName', style: PixiText.label()),
          const SizedBox(height: 6),
        ],
        if (month.total == 0)
          Text(s.t('month_no_data'), style: PixiText.body1(color: PixiColors.muted))
        else ...[
          Text(
            month.previousTotal == 0 ? s.t('pat_first_month') : monthShiftSentence(s, map, month),
            style: PixiText.title(size: compact ? 16 : 18),
          ),
          SizedBox(height: compact ? 12 : 16),
          for (final i in order) row(i),
        ],
      ],
    );
    if (compact) return body;
    return PaperCard(glowColor: map.baseColor, child: body);
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return Text('±0', textAlign: TextAlign.right, style: PixiText.label(size: 11.5, color: PixiColors.faint));
    }
    final up = value > 0;
    return Text(
      up ? '+$value' : '−${value.abs()}',
      textAlign: TextAlign.right,
      style: PixiText.label(size: 11.5, color: up ? PixiColors.ink : PixiColors.muted),
    );
  }
}

/// For every weekday the colour that shows up there especially often.
class WeekdayCard extends StatelessWidget {
  const WeekdayCard({
    super.key,
    required this.map,
    required this.entries,
    required this.year,
    this.compact = false,
  });
  final PixMap map;
  final Map<String, int> entries;
  final int year;

  /// Compact: the three clearest weekdays as sentences, no card around it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stand = weekdayStandouts(map, entries, year);
    if (compact) {
      final top = stand.whereType<WeekdayStandout>().toList()..sort((a, b) => b.lift.compareTo(a.lift));
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in top.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _Chip(color: map.levels[w.level].color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(weekdaySentence(s, map, w), style: PixiText.body1(size: 14, color: PixiColors.ink))),
                ],
              ),
            ),
        ],
      );
    }
    return PaperCard(
      glowColor: map.baseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('pat_week_title'), style: PixiText.label()),
          const SizedBox(height: 4),
          Text(s.t('pat_week_sub'), style: PixiText.label(size: 11, color: PixiColors.muted)),
          const SizedBox(height: 12),
          for (var wd = 0; wd < 7; wd++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(width: 38, child: Text(s.weekdaysShort[wd], style: PixiText.label(size: 12, color: PixiColors.ink))),
                  if (stand[wd] == null) ...[
                    _Chip(color: PixiColors.paperDark),
                    const SizedBox(width: 10),
                    Text(s.t('pat_week_none'), style: PixiText.label(size: 12, color: PixiColors.faint)),
                  ] else ...[
                    _Chip(color: map.levels[stand[wd]!.level].color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.t('pat_week_row').replaceAll('{l}', s.r(map.levels[stand[wd]!.level].label)),
                        style: PixiText.label(size: 12.5, color: PixiColors.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The year as one bar of colours, widths by share. No numbers.
class YearColorsCard extends StatelessWidget {
  const YearColorsCard({super.key, required this.map, required this.entries, required this.year});
  final PixMap map;
  final Map<String, int> entries;
  final int year;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final shares = yearShares(map, entries, year);
    return PaperCard(
      glowColor: map.baseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.t('pat_year_title')} · $year', style: PixiText.label()),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  for (var i = map.levels.length - 1; i >= 0; i--)
                    if (shares[i] > 0)
                      Expanded(
                        flex: max(1, (shares[i] * 1000).round()),
                        child: Container(color: map.levels[i].color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (var i = map.levels.length - 1; i >= 0; i--)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Chip(color: map.levels[i].color, size: 11),
                    const SizedBox(width: 5),
                    Text(s.r(map.levels[i].label), style: PixiText.label(size: 11.5, color: PixiColors.inkSoft)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
