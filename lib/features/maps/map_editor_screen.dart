import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/pix_map.dart';
import '../../models/templates.dart';
import '../../widgets/pixel_grid.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';

/// Edit title, question, base colour and levels of a map.
class MapEditorScreen extends ConsumerStatefulWidget {
  const MapEditorScreen({super.key, required this.mapId, this.isNew = false});
  final String mapId;
  final bool isNew;

  @override
  ConsumerState<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends ConsumerState<MapEditorScreen> {
  late PixMap _map;
  late final TextEditingController _title;
  late final TextEditingController _question;
  late List<TextEditingController> _labels;
  late final S _s;

  @override
  void initState() {
    super.initState();
    _s = S(WidgetsBinding.instance.platformDispatcher.locale);
    final s = _s;
    _map = ref.read(appProvider).maps.firstWhere((m) => m.id == widget.mapId);
    // Template keys are resolved into plain text once the user edits a map.
    _title = TextEditingController(text: s.r(_map.title));
    _question = TextEditingController(text: s.r(_map.question));
    _labels = [for (final l in _map.levels) TextEditingController(text: s.r(l.label))];
  }

  @override
  void dispose() {
    _title.dispose();
    _question.dispose();
    for (final c in _labels) {
      c.dispose();
    }
    super.dispose();
  }

  /// Keeps `@key` values when the user did not change the text so template
  /// maps stay localised; otherwise stores the typed text.
  String _keep(String original, String typed) =>
      typed.trim() == _s.r(original).trim() ? original : typed.trim();

  PixMap _collect() => _map.copyWith(
        title: _keep(_map.title, _title.text),
        question: _keep(_map.question, _question.text),
        levels: [
          for (var i = 0; i < _map.levels.length; i++)
            _map.levels[i].copyWith(label: _keep(_map.levels[i].label, _labels[i].text)),
        ],
      );

  void _save() {
    var m = _collect();
    if (m.title.trim().isEmpty) m = m.copyWith(title: S.of(context).t('custom_map'));
    ref.read(appProvider.notifier).updateMap(m);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('delete_map'), style: PixiText.title(size: 20)),
        content: Text(s.t('delete_map_confirm'), style: PixiText.body1()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('delete'), style: const TextStyle(color: PixiColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(appProvider.notifier).deleteMap(_map.id);
      ref.read(selectedMapIndexProvider.notifier).state = 0;
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _setBase(Color c) {
    // Re-tint levels that came from the old base ramp so custom maps stay coherent.
    final n = _map.levels.length;
    final relit = [
      for (var i = 0; i < n; i++)
        _map.levels[i].copyWith(
          color: _map.templateId == 'custom'
              ? Color.lerp(const Color(0xFFE6E4DE), c, n == 1 ? 1 : i / (n - 1))!
              : _map.levels[i].color,
        ),
    ];
    setState(() => _map = _map.copyWith(baseColor: c, levels: relit));
  }

  Future<void> _pickLevelColor(int i) async {
    final base = _map.baseColor;
    final shades = <Color>[
      const Color(0xFFE6E4DE),
      for (var t = 0.25; t <= 1.0; t += 0.25) Color.lerp(Colors.white, base, t)!,
      Color.lerp(base, Colors.black, 0.35)!,
      ...BaseColors.palette,
    ];
    final picked = await showModalBottomSheet<Color>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in shades)
              GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 10)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        final levels = [..._map.levels];
        levels[i] = levels[i].copyWith(color: picked);
        _map = _map.copyWith(levels: levels);
      });
    }
  }

  void _addLevel() {
    if (_map.levels.length >= 7) return;
    setState(() {
      final levels = [..._map.levels, MapLevel(label: '', color: _map.baseColor)];
      _map = _map.copyWith(levels: levels);
      _labels.add(TextEditingController());
    });
  }

  void _removeLevel(int i) {
    if (_map.levels.length <= 2) return;
    setState(() {
      final levels = [..._map.levels]..removeAt(i);
      _map = _map.copyWith(levels: levels);
      _labels.removeAt(i).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final entries = ref.watch(appProvider).entriesFor(_map.id);
    final year = DateTime.now().year;
    // live preview uses typed labels
    final preview = _map.copyWith(
      levels: [for (var i = 0; i < _map.levels.length; i++) _map.levels[i].copyWith(label: _labels[i].text)],
    );

    return Scaffold(
      backgroundColor: PixiColors.paper,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.isNew ? s.t('new_map') : s.t('edit_map'), style: PixiText.title(size: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(onPressed: _save, child: Text(s.t('save'), style: PixiText.button(color: PixiColors.ink))),
        ],
      ),
      body: GlowBody(
        color: preview.baseColor,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Center(
            child: SizedBox(
              width: 130,
              child: GridCard(
                color: preview.baseColor,
                padding: const EdgeInsets.all(9),
                radius: 14,
                child: PixelGrid(map: preview, entries: entries, year: year, showLabels: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: MapLegend(map: preview, compact: true)),
          const SizedBox(height: 24),
          Text(s.t('map_title_label'), style: PixiText.label()),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: s.t('custom_map')),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          Text(s.t('map_question_label'), style: PixiText.label()),
          const SizedBox(height: 8),
          TextField(
            controller: _question,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: s.isDe ? 'Wie war …?' : 'How was …?'),
          ),
          const SizedBox(height: 22),
          Text(s.t('map_base_color'), style: PixiText.label()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in BaseColors.palette)
                GestureDetector(
                  onTap: () => _setBase(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _map.baseColor.toARGB32() == c.toARGB32() ? PixiColors.ink : Colors.white,
                        width: _map.baseColor.toARGB32() == c.toARGB32() ? 3 : 2,
                      ),
                      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(s.t('map_cat'), style: PixiText.label()),
          const SizedBox(height: 4),
          Text(s.t('map_cat_sub'), style: PixiText.label(size: 12, color: PixiColors.muted)),
          const SizedBox(height: 10),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CatAnims.pickable.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final cat = CatAnims.pickable[i];
                final selected = CatAnims.forMap(_map).id == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _map = _map.copyWith(catId: cat.id)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: PixiColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? PixiColors.ink : PixiColors.line,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (selected)
                              BoxShadow(color: preview.baseColor.withValues(alpha: 0.35), blurRadius: 18),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PixiCat(size: 68, anim: cat, animate: selected),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 76,
                        child: Text(
                          s.t(CatAnims.labelKey(cat.id)),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: PixiText.label(size: 11, color: selected ? PixiColors.ink : PixiColors.muted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Text(s.t('map_levels'), style: PixiText.label()),
          const SizedBox(height: 10),
          for (var i = 0; i < _map.levels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _pickLevelColor(i),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _map.levels[i].color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: _map.baseColor.withValues(alpha: 0.3), blurRadius: 10)],
                      ),
                      child: const Icon(Icons.colorize_rounded, size: 14, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _labels[i],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: s.t('map_level_label'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    onPressed: _map.levels.length <= 2 ? null : () => _removeLevel(i),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: PixiColors.muted,
                  ),
                ],
              ),
            ),
          if (_map.levels.length < 7)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addLevel,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(s.t('add_level')),
                style: TextButton.styleFrom(foregroundColor: PixiColors.ink),
              ),
            ),
          const SizedBox(height: 28),
          PrimaryButton(label: s.t('save'), onPressed: _save),
          const SizedBox(height: 8),
          if (!widget.isNew)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _delete,
                child: Text(s.t('delete_map'), style: PixiText.label(size: 14, color: PixiColors.danger)),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
