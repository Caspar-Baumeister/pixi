import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/demo_data.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../models/templates.dart';
import '../../services/notification_service.dart';
import '../../widgets/circle_year.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';

enum _Step { hi, name, pick, how, time, circle, stats, corr, go }

/// Long, personal onboarding (structure modelled on Amy): progress bar,
/// sketched cat, one question per screen, full-width CTA.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.startStep});

  /// Screenshot mode only: jump straight to a step ('pick', 'how', 'circle' ...).
  final String? startStep;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.hi;
  bool _forward = true;

  final _name = TextEditingController();
  static const _carouselIds = ['mood', 'dreams', 'training'];
  static const _extraIds = ['mood', 'dreams', 'training', 'sleep', 'cry'];

  String _pickedTemplate = 'mood';
  PixMap? _map; // the real first map, created at "pick"
  int? _howLevel;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 30);
  final Set<String> _extraAdded = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final start = widget.startStep;
    if (start != null) {
      _step = _Step.values.firstWhere((e) => e.name == start, orElse: () => _Step.hi);
      if (_Step.values.indexOf(_step) > _Step.values.indexOf(_Step.pick)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _createFirstMap());
      }
    }
  }

  int get _index => _Step.values.indexOf(_step);
  int get _total => _Step.values.length;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _go(_Step s, {bool forward = true}) {
    HapticFeedback.selectionClick();
    setState(() {
      _forward = forward;
      _step = s;
    });
  }

  void _next() {
    switch (_step) {
      case _Step.hi:
        _go(_Step.name);
        break;
      case _Step.name:
        _go(_Step.pick);
        break;
      case _Step.pick:
        _createFirstMap();
        _go(_Step.how);
        break;
      case _Step.how:
        _go(_Step.time);
        break;
      case _Step.time:
        _go(_Step.circle);
        break;
      case _Step.circle:
        _go(_Step.stats);
        break;
      case _Step.stats:
        _go(_Step.corr);
        break;
      case _Step.corr:
        _go(_Step.go);
        break;
      case _Step.go:
        break;
    }
  }

  void _back() {
    if (_index == 0) return;
    _go(_Step.values[_index - 1], forward: false);
  }

  void _createFirstMap() {
    final notifier = ref.read(appProvider.notifier);
    if (_map != null && _map!.templateId == _pickedTemplate) return;
    if (_map != null) notifier.deleteMap(_map!.id);
    final map = templateById(_pickedTemplate).toMap(notifier.newId());
    notifier.addMap(map);
    setState(() {
      _map = map;
      _howLevel = null;
    });
  }

  Future<void> _finish({required bool withReminder}) async {
    setState(() => _busy = true);
    final notifier = ref.read(appProvider.notifier);
    var enabled = false;
    if (withReminder) {
      enabled = await NotificationService.instance.requestPermission();
    }
    notifier.updateSettings((s) => s.copyWith(
          name: _name.text.trim(),
          reminderHour: _time.hour,
          reminderMinute: _time.minute,
          remindersEnabled: enabled,
          onboardingDone: true,
        ));
    if (enabled && mounted) {
      final s = S.of(context);
      await NotificationService.instance.scheduleDaily(
        hour: _time.hour,
        minute: _time.minute,
        title: s.withName('notif_title', _name.text),
        body: s.t('notif_body'),
      );
    }
    await notifier.flush();
    if (mounted) setState(() => _busy = false);
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final accent = _map?.baseColor ?? templateById(_pickedTemplate).baseColor;

    return Scaffold(
      backgroundColor: PixiColors.paper,
      body: Stack(
        children: [
          PageGlow(color: accent),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 24, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: _index == 0 ? null : _back,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: ThinProgress(value: (_index + 1) / _total)),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final offset = Tween<Offset>(
                        begin: Offset(_forward ? 0.08 : -0.08, 0),
                        end: Offset.zero,
                      ).animate(anim);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, if (current != null) current],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(context, s, accent),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: _buildButtons(s),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(S s) {
    switch (_step) {
      case _Step.hi:
        return PrimaryButton(label: s.t('ob_start'), onPressed: _next);
      case _Step.name:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: s.t('next'), onPressed: _next),
          ],
        );
      case _Step.pick:
        return PrimaryButton(label: s.t('ob_pick_choose'), onPressed: _next);
      case _Step.how:
        return PrimaryButton(label: s.t('next'), onPressed: _howLevel == null ? null : _next);
      case _Step.go:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: s.t('ob_go_notif'),
              loading: _busy,
              onPressed: () => _finish(withReminder: true),
            ),
            const SizedBox(height: 4),
            SecondaryButton(
              label: s.t('ob_go_without'),
              onPressed: _busy ? null : () => _finish(withReminder: false),
            ),
          ],
        );
      default:
        return PrimaryButton(label: s.t('next'), onPressed: _next);
    }
  }

  // ---------------------------------------------------------------------------
  // Steps
  // ---------------------------------------------------------------------------

  Widget _header(S s, {required String title, required String subtitle, Widget? illustration}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (illustration != null) Center(child: illustration),
        const SizedBox(height: 8),
        Text(title, style: PixiText.title(size: 28)),
        const SizedBox(height: 8),
        Text(subtitle, style: PixiText.body1(size: 16, color: PixiColors.muted)),
      ],
    );
  }

  Widget _scroll(List<Widget> children) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _buildStep(BuildContext context, S s, Color accent) {
    switch (_step) {
      case _Step.hi:
        return _scroll([
          const SizedBox(height: 16),
          _header(
            s,
            title: s.t('ob_hi_title'),
            subtitle: s.t('ob_hi_sub'),
            illustration: GlowingCat(color: accent, size: 230),
          ),
        ]);

      case _Step.name:
        return _scroll([
          _header(
            s,
            title: s.t('ob_name_title'),
            subtitle: s.t('ob_name_sub'),
            illustration: GlowingCat(color: accent, size: 170),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofocus: false,
            style: PixiText.body1(size: 18, color: PixiColors.ink),
            decoration: InputDecoration(hintText: s.t('ob_name_hint')),
            onSubmitted: (_) => _next(),
            onChanged: (_) => setState(() {}),
          ),
        ]);

      case _Step.pick:
        return _PickStep(
          ids: _carouselIds,
          initialIndex: max(0, _carouselIds.indexOf(_pickedTemplate)),
          title: s.withName('ob_pick_title', _name.text),
          subtitle: s.t('ob_pick_sub'),
          onChanged: (id) => setState(() => _pickedTemplate = id),
        );

      case _Step.how:
        final map = _map!;
        final yesterday = Dates.yesterday();
        final entries = ref.watch(appProvider).entriesFor(map.id);
        return _scroll([
          _header(
            s,
            title: s.r(map.question),
            subtitle: _howLevel == null ? s.t('ob_how_sub') : s.t('ob_how_done'),
            illustration: GlowingCat(color: map.baseColor, size: 150, catId: map.catId),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.t('yesterday')} · ${s.weekdaysShort[yesterday.weekday - 1]} ${yesterday.day}. ${s.monthsShort[yesterday.month - 1]}',
            style: PixiText.label(),
          ),
          const SizedBox(height: 22),
          LevelPicker(
            map: map,
            selected: _howLevel,
            onPick: (lvl) {
              ref.read(appProvider.notifier).setEntry(map.id, yesterday, lvl);
              setState(() => _howLevel = lvl);
            },
          ),
          const SizedBox(height: 26),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _howLevel == null ? 0.0 : 1.0,
            child: Center(
              child: SizedBox(
                width: 150,
                child: GridCard(
                  color: map.baseColor,
                  padding: const EdgeInsets.all(9),
                  radius: 14,
                  child: PixelGrid(
                    map: map,
                    entries: entries,
                    year: yesterday.year,
                    showLabels: false,
                    highlight: yesterday,
                  ),
                ),
              ),
            ),
          ),
        ]);

      case _Step.time:
        return _scroll([
          _header(
            s,
            title: s.t('ob_time_title'),
            subtitle: s.t('ob_time_sub'),
            illustration: GlowingCat(color: accent, size: 150),
          ),
          const SizedBox(height: 22),
          PaperCard(
            onTap: _pickTime,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Text(s.t('ob_time_label'), style: PixiText.label()),
                const SizedBox(height: 6),
                Text(_fmt(_time), style: PixiText.title(size: 56)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.t('ob_time_change'), style: PixiText.label()),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_outlined, size: 15, color: PixiColors.muted),
                  ],
                ),
              ],
            ),
          ),
        ]);

      case _Step.circle:
        final map = _map!;
        final demo = DemoData.forTemplate(map.templateId, map.levels.length, fullYear: true);
        return LayoutBuilder(builder: (context, c) {
          final size = min(c.maxWidth - 32, c.maxHeight - 150).clamp(220.0, 420.0);
          return _scroll([
            _header(s, title: s.t('ob_circle_title'), subtitle: s.t('ob_circle_sub')),
            const SizedBox(height: 14),
            Center(
              child: CircleYear(
                map: map,
                entries: demo,
                year: DateTime.now().year,
                size: size,
                showNumbers: size >= 300,
              ),
            ),
          ]);
        });

      case _Step.stats:
        final map = _map!;
        final demo = DemoData.forTemplate(map.templateId, map.levels.length, fullYear: true);
        return _scroll([
          _header(
            s,
            title: s.t('ob_stats_title'),
            subtitle: s.t('ob_stats_sub'),
            illustration: GlowingCat(color: map.baseColor, size: 130, catId: map.catId),
          ),
          const SizedBox(height: 18),
          _StatsPreview(map: map, entries: demo),
        ]);

      case _Step.corr:
        final map = _map!;
        final demoA = DemoData.forTemplate(map.templateId, map.levels.length, fullYear: true);
        final other = templateById(map.templateId == 'dreams' ? 'sleep' : 'dreams').toMap('demo-b');
        final demoB = DemoData.correlatedWith(demoA, map.levels.length, other.levels.length);
        final year = DateTime.now().year;
        return _scroll([
          _header(s, title: s.t('ob_corr_title'), subtitle: s.t('ob_corr_sub')),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _miniCard(s, other, demoB, year)),
              const SizedBox(width: 12),
              Expanded(child: _miniCard(s, map, demoA, year)),
            ],
          ),
          const SizedBox(height: 16),
          PaperCard(
            glowColor: map.baseColor,
            child: Text(
              s.isDe
                  ? 'Nach guten Nächten war deine „${s.r(map.title)}“ im Schnitt 1,3 Stufen besser.'
                  : 'After good nights your “${s.r(map.title)}” was 1.3 levels better on average.',
              style: PixiText.title(size: 17),
            ),
          ),
          const SizedBox(height: 22),
          Text(s.t('ob_corr_add'), style: PixiText.label()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in _extraIds.where((e) => e != map.templateId))
                _TemplateChip(
                  template: templateById(id),
                  added: _extraAdded.contains(id),
                  onTap: () => _toggleExtra(id),
                ),
            ],
          ),
        ]);

      case _Step.go:
        return _scroll([
          const SizedBox(height: 16),
          _header(
            s,
            title: s.withName('ob_go_title', _name.text),
            subtitle: s.t('ob_go_sub'),
            illustration: GlowingCat(color: accent, size: 230),
          ),
        ]);
    }
  }

  Widget _miniCard(S s, PixMap map, Map<String, int> entries, int year) {
    return Container(
      decoration: BoxDecoration(
        color: PixiColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PixiColors.line),
        boxShadow: [
          BoxShadow(color: map.baseColor.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.r(map.title), style: PixiText.title(size: 15)),
          const SizedBox(height: 8),
          PixelGrid(map: map, entries: entries, year: year, showLabels: false, gapFactor: 0.22),
        ],
      ),
    );
  }

  void _toggleExtra(String id) {
    final notifier = ref.read(appProvider.notifier);
    setState(() {
      if (_extraAdded.contains(id)) {
        _extraAdded.remove(id);
        final existing = ref.read(appProvider).maps.where((m) => m.templateId == id && m.id != _map?.id);
        for (final m in existing) {
          notifier.deleteMap(m.id);
        }
      } else {
        _extraAdded.add(id);
        notifier.addMap(templateById(id).toMap(notifier.newId()));
      }
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: S.of(context).isDe),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// "Womit fangen wir an?" – carousel of big glowing portrait maps
// ---------------------------------------------------------------------------

class _PickStep extends StatefulWidget {
  const _PickStep({
    required this.ids,
    required this.initialIndex,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final List<String> ids;
  final int initialIndex;
  final String title;
  final String subtitle;
  final void Function(String id) onChanged;

  @override
  State<_PickStep> createState() => _PickStepState();
}

class _PickStepState extends State<_PickStep> {
  PageController? _ctrl;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex.toDouble();
  }

  /// Created once with the first measured viewport fraction; later layout
  /// changes (keyboard closing etc.) keep the controller attached.
  void _ensureController(double fraction) {
    if (_ctrl != null) return;
    _ctrl = PageController(viewportFraction: fraction, initialPage: _page.round())
      ..addListener(() {
        setState(() => _page = _ctrl!.page ?? _page);
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final year = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: PixiText.title(size: 28)),
              const SizedBox(height: 8),
              Text(widget.subtitle, style: PixiText.body1(size: 16, color: PixiColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            // Fit the card to the available height: grid + title + legend + padding.
            const chrome = 136.0; // title, subtitle, legend, paddings inside the card
            final gridH = c.maxHeight - chrome - 24;
            final ratio = PixelGrid.heightForWidth(100, showLabels: true) / 100;
            final gridW = (gridH / ratio).clamp(120.0, c.maxWidth * 0.78 - 32);
            final cardW = gridW + 32;
            final fraction = ((cardW + 20) / c.maxWidth).clamp(0.45, 0.86);
            _ensureController(fraction);
            return PageView.builder(
              controller: _ctrl,
              itemCount: widget.ids.length,
              onPageChanged: (i) => widget.onChanged(widget.ids[i]),
              itemBuilder: (context, i) {
                final t = templateById(widget.ids[i]);
                final map = t.toMap('demo-$i');
                final demo = DemoData.preview(t.id, t.levels.length);
                final dist = (_page - i).abs().clamp(0.0, 1.0);
                final scale = 1 - dist * 0.10;
                final selected = dist < 0.5;
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: 1 - dist * 0.35,
                      child: SizedBox(
                        width: cardW,
                        child: MapCard(
                          map: map,
                          entries: demo,
                          year: year,
                          title: s.r(t.titleKey),
                          subtitle: s.r(t.questionKey),
                          selected: selected,
                          onTap: () => _ctrl?.animateToPage(i,
                              duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.ids.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: (_page.round() == i) ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: (_page.round() == i) ? PixiColors.ink : PixiColors.faint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _StatsPreview extends StatelessWidget {
  const _StatsPreview({required this.map, required this.entries});
  final PixMap map;
  final Map<String, int> entries;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final year = DateTime.now().year;
    final sums = List<double>.filled(12, 0);
    final ns = List<int>.filled(12, 0);
    entries.forEach((k, v) {
      if (!k.startsWith('$year-')) return;
      final m = int.parse(k.substring(5, 7)) - 1;
      sums[m] += v;
      ns[m]++;
    });
    final avgs = List.generate(12, (i) => ns[i] == 0 ? 0.0 : sums[i] / ns[i]);
    var best = 0;
    for (var i = 1; i < 12; i++) {
      if (avgs[i] > avgs[best]) best = i;
    }
    final maxLvl = max(1, map.levels.length - 1);
    return PaperCard(
      glowColor: map.baseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('best_month'), style: PixiText.label()),
          const SizedBox(height: 4),
          Text('${s.monthsLong[best]} · Ø ${avgs[best].toStringAsFixed(1).replaceAll('.', s.isDe ? ',' : '.')}',
              style: PixiText.title(size: 22)),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 12; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Container(
                        height: 8 + 82 * (avgs[i] / maxLvl),
                        decoration: BoxDecoration(
                          color: map.levels[(avgs[i]).round().clamp(0, map.levels.length - 1)].color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          boxShadow: [
                            BoxShadow(color: map.baseColor.withValues(alpha: 0.25), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.monthsShort[0], style: PixiText.label(size: 11)),
              Text(s.monthsShort[11], style: PixiText.label(size: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.template, required this.added, required this.onTap});
  final MapTemplate template;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: added ? PixiColors.ink : PixiColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: added ? PixiColors.ink : PixiColors.line),
          boxShadow: [
            BoxShadow(color: template.baseColor.withValues(alpha: 0.25), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: template.baseColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(s.r(template.titleKey),
                style: PixiText.label(size: 13, color: added ? Colors.white : PixiColors.ink)),
            if (added) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
