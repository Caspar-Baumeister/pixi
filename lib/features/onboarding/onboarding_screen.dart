import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/dates.dart';
import '../../core/stats.dart';
import '../../core/demo_data.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../models/templates.dart';
import '../../services/notification_service.dart';
import '../../services/premium_service.dart';
import '../../services/review_service.dart';
import '../premium/paywall_screen.dart';
import '../../widgets/circle_year.dart';
import '../../widgets/hero_ring.dart';
import '../../widgets/links.dart';
import '../../widgets/patterns.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';

enum _Step { hi, name, pick, how, time, circle, stats, corr, support, plan, go }

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
  static const _carouselIds = ['mood', 'dreams', 'training', 'sleep', 'energy'];

  /// Colour sets the start ring glides through: purple, night, green …
  static final _ringSets = [
    for (final id in ['mood', 'sleep', 'training', 'energy', 'cry', 'social', 'meditation', 'dreams', 'gratitude', 'period'])
      templateById(id),
  ];
  static const _extraIds = ['mood', 'dreams', 'training', 'sleep', 'cry'];

  String _pickedTemplate = 'mood';
  PixMap? _map; // the real first map, created at "pick"
  int? _howLevel;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 30);
  final Set<String> _extraAdded = {};
  bool _busy = false;
  bool? _reminderOn;

  // soft paywall
  List<Package>? _packages;
  PackageType _plan = PackageType.monthly;

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
        _loadPackages();
        _go(_Step.support);
        break;
      case _Step.support:
        _go(_Step.plan);
        break;
      case _Step.plan:
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
      enabled = _reminderOn ?? await NotificationService.instance.requestPermission();
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

  Future<void> _loadPackages() async {
    if (_packages != null) return;
    final p = await PremiumService.instance.packages();
    if (mounted) setState(() => _packages = p);
  }

  Package? _pkg(PackageType t) => _packages?.where((p) => p.packageType == t).firstOrNull;

  Future<void> _buyPlan() async {
    final pkg = _pkg(_plan);
    if (pkg == null) {
      _next();
      return;
    }
    setState(() => _busy = true);
    final ok = await PremiumService.instance.purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.read(appProvider.notifier).updateSettings((st) => st.copyWith(premium: true));
    }
    _next();
  }

  Future<void> _rateAndContinue() async {
    await ReviewService.ask();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted && _step == _Step.support) _next();
  }

  Future<void> _askReminder() async {
    setState(() => _busy = true);
    final ok = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _reminderOn = ok;
    });
    _next();
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
          // The big turning pixel ring of the first screen, with Pixi inside.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: _step == _Step.hi
                  ? HeroRing(
                      key: const ValueKey('ring'),
                      templates: _ringSets,
                      child: _heroContent(s),
                    )
                  : const SizedBox.shrink(key: ValueKey('none')),
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
                        icon: Icons.arrow_back_rounded,
                        onTap: _index == 0 ? null : _back,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: ThinProgress(value: (_index + 1) / _total)),
                      if (_step == _Step.plan) ...[
                        const SizedBox(width: 14),
                        DelayedCloseButton(
                          key: const ValueKey('plan-close'),
                          onTap: _busy ? null : _next,
                        ),
                      ],
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
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: PrimaryButton(
            label: s.t('ob_start'),
            color: Colors.white,
            textColor: PixiColors.ink,
            onPressed: _next,
          ),
        );
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
      case _Step.time:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: s.t('ob_time_notif'), loading: _busy, onPressed: _askReminder),
            const SizedBox(height: 4),
            SecondaryButton(
              label: s.t('ob_time_later'),
              onPressed: _busy
                  ? null
                  : () {
                      setState(() => _reminderOn = false);
                      _next();
                    },
            ),
          ],
        );
      case _Step.support:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: s.t('ob_support_rate'), onPressed: _rateAndContinue),
            const SizedBox(height: 4),
            SecondaryButton(label: s.t('ob_support_skip'), onPressed: _next),
          ],
        );
      case _Step.plan:
        return PrimaryButton(
          label: PlanPicker.ctaLabel(s, _packages, _plan),
          loading: _busy,
          onPressed: _buyPlan,
        );
      case _Step.go:
        return PrimaryButton(
          label: s.t('ob_go_start'),
          loading: _busy,
          onPressed: () => _finish(withReminder: _reminderOn == true),
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
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: PixiText.body1(size: 16, color: PixiColors.muted)),
        ],
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
        // Everything lives inside the ring (see build).
        return const SizedBox.shrink();

      case _Step.name:
        return _scroll([
          _header(
            s,
            title: s.t('ob_name_title'),
            subtitle: s.t('ob_name_sub'),
            illustration: GlowingCat(color: accent, size: 150, catId: 'curious'),
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
            illustration: GlowingCat(color: map.baseColor, size: 140, anim: CatAnims.forMap(map)),
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
            illustration: GlowingCat(color: accent, size: 140, catId: 'bell'),
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
            const SizedBox(height: 12),
            // What this wheel shows: the map and its colours.
            Center(
              child: Text('${s.r(map.title)} · ${s.r(map.question)}',
                  textAlign: TextAlign.center, style: PixiText.title(size: 16)),
            ),
            const SizedBox(height: 8),
            Center(child: MapLegend(map: map, compact: true)),
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
            illustration: GlowingCat(color: map.baseColor, size: 120, anim: CatAnims.forMap(map)),
          ),
          const SizedBox(height: 18),
          MonthShiftCard(map: map, month: _demoMonth(map, demo)),
          const SizedBox(height: 12),
          PaperCard(
            glowColor: map.baseColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('pat_week_title'), style: PixiText.label()),
                const SizedBox(height: 12),
                WeekdayCard(map: map, entries: demo, year: DateTime.now().year, compact: true),
              ],
            ),
          ),
        ]);

      case _Step.corr:
        final map = _map!;
        final demoA = DemoData.forTemplate(map.templateId, map.levels.length, fullYear: true);
        final other = templateById(map.templateId == 'sleep' ? 'mood' : 'sleep').toMap('demo-b');
        final demoB = DemoData.correlatedWith(demoA, map.levels.length, other.levels.length);
        final year = DateTime.now().year;
        return _scroll([
          _header(s, title: s.t('ob_corr_title'), subtitle: s.t('ob_corr_sub')),
          const SizedBox(height: 18),
          PaperCard(
            glowColor: map.baseColor,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('links_title'), style: PixiText.label()),
                const SizedBox(height: 4),
                for (final l in linksBetween(other, demoB, map, demoA).take(3)) LinkRow(link: l),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _miniCard(s, other, demoB, year)),
              const SizedBox(width: 12),
              Expanded(child: _miniCard(s, map, demoA, year)),
            ],
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

      case _Step.support:
        return _scroll([
          const SizedBox(height: 8),
          _header(
            s,
            title: s.t('ob_support_title'),
            subtitle: s.t('ob_support_sub'),
            illustration: GlowingCat(color: accent, size: 190, catId: 'gratitude'),
          ),
        ]);

      case _Step.plan:
        return _scroll([
          const SizedBox(height: 8),
          _header(
            s,
            title: s.t('ob_plan_title'),
            subtitle: s.t('ob_plan_sub'),
            illustration: GlowingCat(color: accent, size: 130, catId: 'happy'),
          ),
          const SizedBox(height: 18),
          PlanPicker(
            packages: _packages,
            selected: _plan,
            onSelect: (p) => setState(() => _plan = p),
          ),
        ]);

      case _Step.go:
        return _scroll([
          const SizedBox(height: 16),
          _header(
            s,
            title: s.withName('ob_go_title', _name.text),
            // Only promise the morning message when the reminder is really on.
            subtitle: _reminderOn == true ? s.t('ob_go_sub') : '',
            illustration: GlowingCat(color: accent, size: 200, catId: 'happy'),
          ),
        ]);
    }
  }

  /// Cat, title and line inside the start ring.
  Widget _heroContent(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixiCat(size: 190, catId: 'wave'),
          const SizedBox(height: 10),
          Text(s.t('ob_hi_title'), textAlign: TextAlign.center, style: PixiText.title(size: 30)),
          const SizedBox(height: 8),
          Text(s.t('ob_hi_sub'), textAlign: TextAlign.center, style: PixiText.body1(size: 15, color: PixiColors.muted)),
        ],
      ),
    );
  }

  /// The demo year's current month (February at the earliest, so there is
  /// always a month before it to compare with).
  MonthColors _demoMonth(PixMap map, Map<String, int> demo) =>
      monthColors(map, demo, DateTime.now().year, max(2, DateTime.now().month));

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
                      // Maps with many levels have a taller legend: shrink
                      // the card a little instead of overflowing.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: c.maxHeight - 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
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
