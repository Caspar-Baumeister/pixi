import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/links.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../services/share_service.dart';
import '../../widgets/circle_year.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/ui.dart';
import '../home/day_sheet.dart';

/// Poster view of the maps as year wheels. Swipe left and right to switch
/// between maps; the share button shares the wheel you are looking at.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key, required this.mapId});

  /// The map to open first.
  final String mapId;

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  final Map<String, GlobalKey> _shareKeys = {};
  PageController? _pager;
  int _index = 0;
  bool _sharing = false;

  GlobalKey _keyFor(String id) => _shareKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void dispose() {
    _pager?.dispose();
    super.dispose();
  }

  void _jump(int to, int count) {
    if (to < 0 || to >= count) return;
    HapticFeedback.selectionClick();
    _pager?.animateToPage(to, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final year = ref.watch(selectedYearProvider);
    final maps = data.maps;
    if (maps.isEmpty) return const Scaffold(body: SizedBox.shrink());
    if (_pager == null) {
      _index = maps.indexWhere((m) => m.id == widget.mapId).clamp(0, maps.length - 1);
      _pager = PageController(initialPage: _index);
    }
    final index = _index.clamp(0, maps.length - 1);
    final current = maps[index];

    return Scaffold(
      backgroundColor: PixiColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: index > 0 ? () => _jump(index - 1, maps.length) : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
              color: PixiColors.ink,
              disabledColor: PixiColors.line,
              visualDensity: VisualDensity.compact,
            ),
            Flexible(
              child: Text(
                _title(s, current),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PixiText.title(size: 20),
              ),
            ),
            IconButton(
              onPressed: index < maps.length - 1 ? () => _jump(index + 1, maps.length) : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 26),
              color: PixiColors.ink,
              disabledColor: PixiColors.line,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pager,
              itemCount: maps.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                // keep the home screen on the same map
                ref.read(selectedMapIndexProvider.notifier).state = i;
              },
              itemBuilder: (context, i) => _WheelPage(
                map: maps[i],
                entries: data.entriesFor(maps[i].id),
                year: year,
                shareKey: _keyFor(maps[i].id),
                title: _title(s, maps[i]),
              ),
            ),
          ),
          if (maps.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < maps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == index ? PixiColors.ink : PixiColors.faint,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Builder(
              builder: (btnCtx) => PrimaryButton(
                label: s.t('share'),
                loading: _sharing,
                onPressed: () async {
                  setState(() => _sharing = true);
                  final ok = await ShareService.shareBoundary(
                    _keyFor(current.id),
                    fileName: 'pixi_circle_${_title(s, current)}_$year.png',
                    text: '${s.t('share_text')}\n${Links.appStore}',
                    origin: btnCtx,
                  );
                  if (!mounted) return;
                  setState(() => _sharing = false);
                  if (!ok) {
                    ScaffoldMessenger.of(this.context)
                        .showSnackBar(SnackBar(content: Text(s.t('share_failed'))));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _title(S s, PixMap m) => s.r(m.title).isEmpty ? s.t('custom_map') : s.r(m.title);
}

class _WheelPage extends StatelessWidget {
  const _WheelPage({
    required this.map,
    required this.entries,
    required this.year,
    required this.shareKey,
    required this.title,
  });

  final PixMap map;
  final Map<String, int> entries;
  final int year;
  final GlobalKey shareKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: RepaintBoundary(
          key: shareKey,
          child: Container(
            color: PixiColors.paper,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: LayoutBuilder(builder: (context, c) {
              final size = (c.maxWidth - 8).clamp(240.0, 420.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleYear(
                    map: map,
                    entries: entries,
                    year: year,
                    size: size,
                    onTapDay: (d) => DaySheet.show(context, date: d, primaryMapId: map.id),
                  ),
                  const SizedBox(height: 14),
                  Text('$title · $year', style: PixiText.title(size: 16)),
                  const SizedBox(height: 8),
                  MapLegend(map: map, compact: true),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
