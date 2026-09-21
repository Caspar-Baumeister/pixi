import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/stats.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/ui.dart';
import '../premium/paywall_screen.dart';
import 'map_editor_screen.dart';
import 'templates_screen.dart';

/// Overview of all maps: reorder, open editor, add new.
class MapsScreen extends ConsumerWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final maps = data.maps;
    final premium = data.settings.premium;
    final year = ref.watch(selectedYearProvider);

    return Scaffold(
      backgroundColor: PixiColors.paper,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(s.t('maps_title'), style: PixiText.title(size: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GlowBody(
        color: (maps.isEmpty ? PixiColors.faint : maps[ref.watch(selectedMapIndexProvider).clamp(0, maps.length - 1)].baseColor),
        child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: maps.length,
              onReorder: (a, b) => ref.read(appProvider.notifier).reorderMaps(a, b),
              proxyDecorator: (child, i, anim) => Material(color: Colors.transparent, child: child),
              itemBuilder: (context, i) {
                final m = maps[i];
                final entries = data.entriesFor(m.id);
                final stats = computeStats(m, entries, year);
                return Padding(
                  key: ValueKey(m.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaperCard(
                    glowColor: m.baseColor,
                    padding: const EdgeInsets.all(14),
                    onTap: () {
                      ref.read(selectedMapIndexProvider.notifier).state = i;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MapEditorScreen(mapId: m.id)),
                      );
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 54,
                          child: PixelGrid(map: m, entries: entries, year: year, showLabels: false, gapFactor: 0.25),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.r(m.title), style: PixiText.title(size: 18)),
                              const SizedBox(height: 2),
                              Text(s.r(m.question), style: PixiText.label(), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text('${stats.count} ${s.t('days_filled')} · ${s.t('streak')} ${stats.streak}',
                                  style: PixiText.label(size: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_indicator_rounded, color: PixiColors.faint),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              premium ? '${maps.length} · ${s.t('premium')}' : '${maps.length} / $kFreeMapLimit ${s.t('free').toLowerCase()}',
              style: PixiText.label(size: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: PrimaryButton(
              label: s.t('new_map'),
              onPressed: () {
                if (!ref.read(appProvider.notifier).canAddMap) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen(reason: PaywallReason.maps)));
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TemplatesScreen()));
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
