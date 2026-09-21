import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/circle_year.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/ui.dart';
import '../home/day_sheet.dart';

/// Poster view of one map with share button.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key, required this.mapId});
  final String mapId;

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  final _shareKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final year = ref.watch(selectedYearProvider);
    final map = data.maps.where((m) => m.id == widget.mapId).firstOrNull;
    if (map == null) return const Scaffold(body: SizedBox.shrink());
    final entries = data.entriesFor(map.id);

    return Scaffold(
      backgroundColor: PixiColors.paper,
      appBar: AppBar(
        title: Text(s.r(map.title), style: PixiText.title(size: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _shareKey,
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
                          Text('${s.r(map.title)} · $year', style: PixiText.title(size: 16)),
                          const SizedBox(height: 8),
                          MapLegend(map: map, compact: true),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: PrimaryButton(
              label: s.t('share'),
              loading: _sharing,
              onPressed: () async {
                setState(() => _sharing = true);
                await ShareService.shareBoundary(
                  _shareKey,
                  fileName: 'pixi_circle_${s.r(map.title)}_$year.png',
                  text: s.t('share_text'),
                );
                if (mounted) setState(() => _sharing = false);
              },
            ),
          ),
        ],
      ),
    );
  }
}
