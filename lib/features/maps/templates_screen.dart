import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/demo_data.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/templates.dart';
import '../../widgets/pixel_grid.dart';
import '../premium/paywall_screen.dart';
import 'map_editor_screen.dart';

/// "Neue Map": templates in categories, plus a custom map.
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  TemplateCategory _cat = TemplateCategory.feelings;

  String _catLabel(S s, TemplateCategory c) {
    switch (c) {
      case TemplateCategory.feelings:
        return s.t('cat_feelings');
      case TemplateCategory.body:
        return s.t('cat_body');
      case TemplateCategory.habits:
        return s.t('cat_habits');
      case TemplateCategory.custom:
        return s.t('cat_custom');
    }
  }

  bool _gate() {
    if (ref.read(appProvider.notifier).canAddMap) return true;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen(reason: PaywallReason.maps)));
    return false;
  }

  void _addTemplate(MapTemplate t) {
    if (!_gate()) return;
    final notifier = ref.read(appProvider.notifier);
    final map = t.toMap(notifier.newId());
    notifier.addMap(map);
    ref.read(selectedMapIndexProvider.notifier).state = ref.read(appProvider).maps.length - 1;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _addCustom(Color base) {
    if (!_gate()) return;
    final notifier = ref.read(appProvider.notifier);
    final map = customMap(notifier.newId(), base);
    notifier.addMap(map);
    ref.read(selectedMapIndexProvider.notifier).state = ref.read(appProvider).maps.length - 1;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MapEditorScreen(mapId: map.id, isNew: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final year = DateTime.now().year;
    final items = kTemplates.where((t) => t.category == _cat).toList();

    return Scaffold(
      backgroundColor: PixiColors.paper,
      appBar: AppBar(
        title: Text(s.t('new_map'), style: PixiText.title(size: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final c in TemplateCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_catLabel(s, c)),
                      selected: _cat == c,
                      onSelected: (_) => setState(() => _cat = c),
                      selectedColor: PixiColors.ink,
                      backgroundColor: PixiColors.card,
                      side: const BorderSide(color: PixiColors.line),
                      showCheckmark: false,
                      labelStyle: PixiText.label(size: 13, color: _cat == c ? Colors.white : PixiColors.ink),
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _cat == TemplateCategory.custom
                ? _CustomPicker(onPick: _addCustom)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final t = items[i];
                      final map = t.toMap('tpl-${t.id}');
                      final demo = DemoData.preview(t.id, t.levels.length);
                      return GestureDetector(
                        onTap: () => _addTemplate(t),
                        child: Container(
                          decoration: BoxDecoration(
                            color: PixiColors.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: PixiColors.line),
                            boxShadow: [
                              BoxShadow(color: t.baseColor.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 8)),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.r(t.titleKey), style: PixiText.title(size: 16)),
                              Text(s.r(t.questionKey), style: PixiText.label(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: LayoutBuilder(builder: (context, c) {
                                    final ratio = PixelGrid.heightForWidth(100, showLabels: false) / 100;
                                    final w = (c.maxHeight / ratio).clamp(40.0, c.maxWidth);
                                    return SizedBox(
                                      width: w,
                                      child: PixelGrid(map: map, entries: demo, year: year, showLabels: false, gapFactor: 0.22),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final l in t.levels)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(color: l.color, borderRadius: BorderRadius.circular(3)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomPicker extends StatelessWidget {
  const _CustomPicker({required this.onPick});
  final void Function(Color) onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(s.t('custom_map'), style: PixiText.title(size: 22)),
        const SizedBox(height: 6),
        Text(s.t('custom_map_sub'), style: PixiText.body1(color: PixiColors.muted)),
        const SizedBox(height: 20),
        Text(s.t('map_base_color'), style: PixiText.label()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final c in BaseColors.palette)
              GestureDetector(
                onTap: () => onPick(c),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
