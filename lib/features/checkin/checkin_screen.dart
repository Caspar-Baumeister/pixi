import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/dates.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';
import '../feedback/feedback_sheet.dart';

/// Morning flow: one question per map, cat reacts, tap a colour, next.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  late final PageController _pager;
  int _page = 0;
  late DateTime _date;
  final Map<String, int> _picked = {};
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    // Before noon we ask about yesterday, afterwards about today.
    _date = DateTime.now().hour < 12 ? Dates.yesterday() : Dates.today();
    _pager = PageController();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_advancing) return;
    _advancing = true;
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    final next = _page + 1;
    await _pager.animateToPage(next, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    _advancing = false;
  }

  void _pick(PixMap map, int lvl) {
    HapticFeedback.mediumImpact();
    ref.read(appProvider.notifier).setEntry(map.id, _date, lvl);
    setState(() => _picked[map.id] = lvl);
    _advance();
  }

  void _finish() {
    final notifier = ref.read(appProvider.notifier);
    final settings = ref.read(appProvider).settings;
    final first = settings.checkinCount == 0 && !settings.feedbackAfterCheckinShown;
    notifier.markCheckinDone(_date);
    Navigator.of(context).pop();
    if (first) {
      notifier.updateSettings((s) => s.copyWith(feedbackAfterCheckinShown: true));
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) FeedbackSheet.show(ctx, kind: FeedbackKind.firstCheckin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final maps = data.maps;
    if (maps.isEmpty) {
      return Scaffold(
        backgroundColor: PixiColors.paper,
        body: Center(child: Text(s.t('no_maps_title'), style: PixiText.title())),
      );
    }
    final total = maps.length + 1;
    final onSummary = _page >= maps.length;
    final accent = onSummary ? (maps.isEmpty ? PixiColors.faint : maps.last.baseColor) : maps[_page].baseColor;

    return Scaffold(
      backgroundColor: PixiColors.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 24, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: _page == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
                        onTap: () {
                          if (_page == 0) {
                            Navigator.of(context).pop();
                          } else {
                            _pager.previousPage(
                                duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: ThinProgress(value: (_page + 1) / total, color: accent.isDark ? PixiColors.ink : accent)),
                      const SizedBox(width: 14),
                      Text(s.t('ci_progress').replaceAll('{a}', '${(_page + 1).clamp(1, maps.length)}').replaceAll('{b}', '${maps.length}'),
                          style: PixiText.label()),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: total,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      if (i >= maps.length) return _Summary(maps: maps, date: _date, picked: _picked, onDone: _finish);
                      return _Question(
                        map: maps[i],
                        date: _date,
                        showDateToggle: i == 0,
                        selected: _picked[maps[i].id] ?? data.entriesFor(maps[i].id)[Dates.key(_date)],
                        greeting: i == 0 ? s.withName('ci_title', data.settings.name) : null,
                        onDateChanged: (d) => setState(() {
                          _date = d;
                          _picked.clear();
                        }),
                        onPick: (lvl) => _pick(maps[i], lvl),
                        onSkip: _advance,
                      );
                    },
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

class _Question extends StatelessWidget {
  const _Question({
    required this.map,
    required this.date,
    required this.showDateToggle,
    required this.selected,
    required this.greeting,
    required this.onDateChanged,
    required this.onPick,
    required this.onSkip,
  });

  final PixMap map;
  final DateTime date;
  final bool showDateToggle;
  final int? selected;
  final String? greeting;
  final void Function(DateTime) onDateChanged;
  final void Function(int) onPick;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isYesterday = Dates.sameDay(date, Dates.yesterday());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              scale: selected == null ? 1 : 1.06,
              child: GlowingCat(color: map.baseColor, size: 190, catId: map.catId),
            ),
          ),
          if (greeting != null) ...[
            Text(greeting!, style: PixiText.label(size: 14)),
            const SizedBox(height: 4),
          ],
          Text(s.r(map.question), style: PixiText.title(size: 28)),
          const SizedBox(height: 10),
          if (showDateToggle)
            Row(
              children: [
                _DateChip(
                  label: s.t('yesterday'),
                  active: isYesterday,
                  onTap: () => onDateChanged(Dates.yesterday()),
                ),
                const SizedBox(width: 8),
                _DateChip(
                  label: s.t('today'),
                  active: !isYesterday,
                  onTap: () => onDateChanged(Dates.today()),
                ),
                const SizedBox(width: 12),
                Text('${s.weekdaysShort[date.weekday - 1]} ${date.day}. ${s.monthsShort[date.month - 1]}',
                    style: PixiText.label()),
              ],
            )
          else
            Text(
              '${isYesterday ? s.t('yesterday') : s.t('today')} · ${s.weekdaysShort[date.weekday - 1]} ${date.day}. ${s.monthsShort[date.month - 1]}',
              style: PixiText.label(),
            ),
          const SizedBox(height: 30),
          LevelPicker(map: map, selected: selected, onPick: onPick, size: 56),
          const SizedBox(height: 26),
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: Text(s.t('ci_skip_map'), style: PixiText.label(size: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? PixiColors.ink : PixiColors.paperDark,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: PixiText.label(size: 12, color: active ? Colors.white : PixiColors.inkSoft)),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.maps, required this.date, required this.picked, required this.onDone});
  final List<PixMap> maps;
  final DateTime date;
  final Map<String, int> picked;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: PixiCat(size: 170)),
                Text(s.t('ci_summary_title'), style: PixiText.title(size: 28)),
                const SizedBox(height: 6),
                Text(s.t('ci_summary_sub'), style: PixiText.body1(color: PixiColors.muted)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final m in maps)
                      SizedBox(
                        width: 92,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PixelGrid(
                              map: m,
                              entries: data.entriesFor(m.id),
                              year: date.year,
                              showLabels: false,
                              highlight: date,
                              gapFactor: 0.25,
                            ),
                            const SizedBox(height: 6),
                            Text(s.r(m.title), style: PixiText.label(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              picked[m.id] != null || data.entriesFor(m.id)[Dates.key(date)] != null
                                  ? s.r(m.levels[(picked[m.id] ?? data.entriesFor(m.id)[Dates.key(date)]!).clamp(0, m.levels.length - 1)].label)
                                  : '–',
                              style: PixiText.label(size: 11, color: PixiColors.ink),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: PrimaryButton(label: s.t('done'), onPressed: onDone),
        ),
      ],
    );
  }
}
