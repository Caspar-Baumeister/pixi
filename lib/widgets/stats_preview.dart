import 'dart:math';

import 'package:flutter/material.dart';

import '../core/demo_data.dart';
import '../core/stats.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/pix_map.dart';
import '../models/templates.dart';
import 'links.dart';

/// Example data for previews (paywall, onboarding): mood, sleep and
/// training that really are related, so the links look like real ones.
class DemoTrio {
  DemoTrio._();
  static final PixMap mood = templateById('mood').toMap('demo-mood');
  static final PixMap sleep = templateById('sleep').toMap('demo-sleep');
  static final PixMap training = templateById('training').toMap('demo-training');
  static final Map<String, int> moodData =
      DemoData.forTemplate('mood', mood.levels.length, fullYear: true);
  static final Map<String, int> sleepData =
      DemoData.correlatedWith(moodData, mood.levels.length, sleep.levels.length);
  static final Map<String, int> trainingData =
      DemoData.correlatedWith(moodData, mood.levels.length, training.levels.length);

  static List<LevelLink> links() {
    final all = computeLinks(
      [mood, sleep, training],
      {mood.id: moodData, sleep.id: sleepData, training.id: trainingData},
    );
    // Lead with an uplifting pair (both on the "good" end), e.g.
    // Beast Mode ⟷ Radiant, then the rest by strength.
    bool high(LevelLink l) => l.la >= l.a.levels.length - 2 && l.lb >= l.b.levels.length - 2;
    final first = all.where(high).toList();
    return [...first.take(2), ...all.where((l) => !first.take(2).contains(l))];
  }
}

/// Swipeable cards: what Premium statistics show and why they help.
class PremiumStatsPreview extends StatefulWidget {
  const PremiumStatsPreview({super.key});

  @override
  State<PremiumStatsPreview> createState() => _PremiumStatsPreviewState();
}

class _PremiumStatsPreviewState extends State<PremiumStatsPreview> {
  final _pc = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final year = DateTime.now().year;
    final st = computeStats(DemoTrio.mood, DemoTrio.moodData, year);
    final maxV = max(1, DemoTrio.mood.levels.length - 1).toDouble();
    final cards = <Widget>[
      _card(
        title: s.t('links_title'),
        why: s.t('pw_links_why'),
        child: Column(children: [for (final l in DemoTrio.links().take(3)) LinkRow(link: l)]),
      ),
      _card(
        title: s.t('pw_month_title'),
        why: s.t('pw_month_why'),
        child: MiniBars(values: st.monthAverages, maxValue: maxV, labels: s.monthLetters, map: DemoTrio.mood),
      ),
      _card(
        title: s.t('pw_week_title'),
        why: s.t('pw_week_why'),
        child: MiniBars(values: st.weekdayAverages, maxValue: maxV, labels: s.weekdaysShort, map: DemoTrio.mood),
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView(
            controller: _pc,
            padEnds: false,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final c in cards) Padding(padding: const EdgeInsets.only(right: 12, bottom: 14), child: c),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < cards.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _page ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? PixiColors.ink : PixiColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _card({required String title, required String why, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: PixiColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: DemoTrio.mood.baseColor.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PixiText.title(size: 18)),
          const SizedBox(height: 8),
          Expanded(child: Center(child: child)),
          const SizedBox(height: 8),
          Text(why, style: PixiText.label(size: 12, color: PixiColors.inkSoft), maxLines: 4, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Compact bar chart coloured with the map's level colours.
class MiniBars extends StatelessWidget {
  const MiniBars({super.key, required this.values, required this.maxValue, required this.labels, required this.map, this.height = 90});
  final List<double?> values;
  final double maxValue;
  final List<String> labels;
  final PixMap map;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Container(
                      height: values[i] == null ? 6 : 8 + (height - 10) * (values[i]! / maxValue),
                      decoration: BoxDecoration(
                        color: values[i] == null
                            ? PixiColors.paperDark
                            : map.levels[values[i]!.round().clamp(0, map.levels.length - 1)].color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(children: [
          for (final l in labels) Expanded(child: Text(l, textAlign: TextAlign.center, style: PixiText.label(size: 10))),
        ]),
      ],
    );
  }
}
