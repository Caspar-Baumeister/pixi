import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/stats.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../services/share_service.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';
import '../checkin/checkin_screen.dart';
import '../circle/circle_screen.dart';
import '../feedback/feedback_sheet.dart';
import '../maps/maps_screen.dart';
import '../maps/templates_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'day_sheet.dart';

/// The year view: one big glowing grid per map, swipe to switch maps.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pager;
  final Map<String, GlobalKey> _shareKeys = {};

  @override
  void initState() {
    super.initState();
    _pager = PageController(initialPage: ref.read(selectedMapIndexProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskFeedback());
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _maybeAskFeedback() {
    final data = ref.read(appProvider);
    if (data.maps.isNotEmpty && !data.settings.feedbackAfterMapShown) {
      ref.read(appProvider.notifier).updateSettings((s) => s.copyWith(feedbackAfterMapShown: true));
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) FeedbackSheet.show(context, kind: FeedbackKind.firstMap);
      });
    }
  }

  void _jump(int index, int count) {
    if (count == 0) return;
    final target = index.clamp(0, count - 1);
    HapticFeedback.selectionClick();
    _pager.animateToPage(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  GlobalKey _keyFor(String id) => _shareKeys.putIfAbsent(id, () => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Keep the pager in sync when the selected map changes elsewhere
    // (new map added, map picked in the overview …).
    ref.listen<int>(selectedMapIndexProvider, (prev, next) {
      if (_pager.hasClients && (_pager.page ?? -1).round() != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pager.hasClients) _pager.jumpToPage(next);
        });
      }
    });
    final data = ref.watch(appProvider);
    final maps = data.maps;
    final year = ref.watch(selectedYearProvider);
    var index = ref.watch(selectedMapIndexProvider);
    if (index >= maps.length) index = maps.isEmpty ? 0 : maps.length - 1;
    final current = maps.isEmpty ? null : maps[index];
    final accent = current?.baseColor ?? PixiColors.faint;
    final checkinDone = ref.read(appProvider.notifier).checkinDoneToday;

    return Scaffold(
      backgroundColor: PixiColors.paper,
      body: Stack(
        children: [
          PageGlow(color: accent),
          SafeArea(
            child: Column(
              children: [
                // ---- top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.grid_view_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MapsScreen()),
                        ),
                      ),
                      Expanded(
                        child: current == null
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _Arrow(
                                    icon: Icons.chevron_left_rounded,
                                    enabled: index > 0,
                                    onTap: () => _jump(index - 1, maps.length),
                                  ),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () => _pickYear(context, year),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            s.r(current.title).isEmpty ? s.t('custom_map') : s.r(current.title),
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: PixiText.title(size: 22),
                                          ),
                                          Text('$year', style: PixiText.label(size: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _Arrow(
                                    icon: Icons.chevron_right_rounded,
                                    enabled: index < maps.length - 1,
                                    onTap: () => _jump(index + 1, maps.length),
                                  ),
                                ],
                              ),
                      ),
                      CircleIconButton(
                        icon: Icons.tune_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---- content
                Expanded(
                  child: maps.isEmpty
                      ? _EmptyState(onAdd: () => _addMap(context))
                      : PageView.builder(
                          controller: _pager,
                          itemCount: maps.length,
                          onPageChanged: (i) => ref.read(selectedMapIndexProvider.notifier).state = i,
                          itemBuilder: (context, i) => _MapPage(
                            map: maps[i],
                            entries: data.entriesFor(maps[i].id),
                            year: year,
                            shareKey: _keyFor(maps[i].id),
                            onTapDay: (d) => DaySheet.show(context, date: d, primaryMapId: maps[i].id),
                          ),
                        ),
                ),

                // ---- bottom actions
                if (current != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: checkinDone ? s.t('checkin_done_today') : s.t('checkin_cta'),
                            color: checkinDone ? PixiColors.paperDark : PixiColors.ink,
                            textColor: checkinDone ? PixiColors.inkSoft : Colors.white,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CheckinScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _RoundAction(
                          icon: Icons.donut_large_rounded,
                          tooltip: s.t('circle_view'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CircleScreen(mapId: current.id)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundAction(
                          icon: Icons.insights_rounded,
                          tooltip: s.t('stats'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StatsScreen(mapId: current.id)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundAction(
                          icon: Icons.ios_share_rounded,
                          tooltip: s.t('share'),
                          onTap: () => ShareService.shareBoundary(
                            _keyFor(current.id),
                            fileName: 'pixi_${s.r(current.title)}_$year.png',
                            text: s.t('share_text'),
                          ),
                        ),
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

  Future<void> _addMap(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TemplatesScreen()));
  }

  Future<void> _pickYear(BuildContext context, int year) async {
    final now = DateTime.now().year;
    final years = [for (var y = now - 4; y <= now + 1; y++) y];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (final y in years)
              ListTile(
                title: Text('$y', textAlign: TextAlign.center,
                    style: PixiText.title(size: 20, color: y == year ? PixiColors.ink : PixiColors.muted)),
                onTap: () => Navigator.pop(context, y),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(selectedYearProvider.notifier).state = picked;
  }
}

const double _cardPad = 10;

class _MapPage extends StatelessWidget {
  const _MapPage({
    required this.map,
    required this.entries,
    required this.year,
    required this.shareKey,
    required this.onTapDay,
  });

  final PixMap map;
  final Map<String, int> entries;
  final int year;
  final GlobalKey shareKey;
  final void Function(DateTime) onTapDay;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stats = computeStats(map, entries, year);
    return LayoutBuilder(builder: (context, c) {
      // The grid fills the height; legend + stats sit in a slim column beside it.
      const sideW = 84.0;
      const gap = 14.0;
      const padH = 16.0;
      final ratio = PixelGrid.heightForWidth(100) / 100;
      const card = _cardPad * 2;
      final maxByHeight = (c.maxHeight - 24 - card) / ratio + card;
      final maxByWidth = c.maxWidth - padH * 2 - sideW - gap;
      final gridW = maxByHeight.clamp(150.0, maxByWidth);
      return Center(
        child: RepaintBoundary(
          key: shareKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: padH, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: gridW,
                  child: GridCard(
                    color: map.baseColor,
                    padding: const EdgeInsets.all(_cardPad),
                    child: PixelGrid(map: map, entries: entries, year: year, onTapDay: onTapDay),
                  ),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: sideW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MapLegend(map: map, vertical: true),
                      const SizedBox(height: 22),
                      _Stat(value: '${stats.count}', label: s.t('days_filled')),
                      const SizedBox(height: 12),
                      _Stat(value: '${stats.streak}', label: s.t('streak')),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: PixiText.title(size: 24)),
        Text(label, style: PixiText.label(size: 11), maxLines: 2),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 28),
      color: PixiColors.ink,
      disabledColor: PixiColors.line,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: PixiColors.card,
        shape: const CircleBorder(side: BorderSide(color: PixiColors.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(icon, size: 22, color: PixiColors.ink),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PixiCat(size: 200),
          const SizedBox(height: 16),
          Text(s.t('no_maps_title'), style: PixiText.title(size: 26), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(s.t('no_maps_sub'), style: PixiText.body1(color: PixiColors.muted), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          PrimaryButton(label: s.t('add_map'), onPressed: onAdd),
        ],
      ),
    );
  }
}
