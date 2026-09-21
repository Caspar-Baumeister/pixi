import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/pixi_cat.dart';
import '../../widgets/ui.dart';

/// Bottom sheet for one day: every map's level picker, primary map first.
class DaySheet extends ConsumerWidget {
  const DaySheet({super.key, required this.date, required this.primaryMapId});

  final DateTime date;
  final String primaryMapId;

  static Future<void> show(BuildContext context, {required DateTime date, required String primaryMapId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DaySheet(date: date, primaryMapId: primaryMapId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final data = ref.watch(appProvider);
    final maps = [...data.maps]..sort((a, b) => a.id == primaryMapId ? -1 : (b.id == primaryMapId ? 1 : 0));
    final isFuture = Dates.isFuture(date);
    final label = Dates.sameDay(date, Dates.today())
        ? s.t('today')
        : Dates.sameDay(date, Dates.yesterday())
            ? s.t('yesterday')
            : s.weekdaysShort[date.weekday - 1];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: maps.length > 1 ? 0.7 : 0.48,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: PixiColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PixiText.label()),
                    Text('${date.day}. ${s.monthsLong[date.month - 1]} ${date.year}',
                        style: PixiText.title(size: 24)),
                  ],
                ),
              ),
              PixiCat(size: 64, catId: maps.isEmpty ? 'pixi' : maps.first.catId),
            ],
          ),
          if (isFuture) ...[
            const SizedBox(height: 18),
            Text(s.isDe ? 'Der Tag liegt noch vor dir.' : 'That day is still ahead of you.',
                style: PixiText.body1(color: PixiColors.muted)),
          ] else
            for (final m in maps) ...[
              const SizedBox(height: 22),
              Text(s.r(m.title), style: PixiText.title(size: 17)),
              const SizedBox(height: 2),
              Text(s.r(m.question), style: PixiText.label()),
              const SizedBox(height: 14),
              LevelPicker(
                map: m,
                size: 46,
                selected: data.entriesFor(m.id)[Dates.key(date)],
                onPick: (lvl) {
                  final cur = data.entriesFor(m.id)[Dates.key(date)];
                  ref.read(appProvider.notifier).setEntry(m.id, date, cur == lvl ? null : lvl);
                },
              ),
              if (data.entriesFor(m.id)[Dates.key(date)] != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ref.read(appProvider.notifier).setEntry(m.id, date, null),
                    child: Text(s.t('clear_entry'), style: PixiText.label(size: 12)),
                  ),
                ),
              const Divider(height: 8),
            ],
        ],
      ),
    );
  }
}
