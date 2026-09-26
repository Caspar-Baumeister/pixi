import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../core/screenshot_mode.dart';
import '../models/pix_map.dart';
import 'repository.dart';

/// Overridden in `main()` with the loaded data / repository.
final repositoryProvider = Provider<Repository>((ref) {
  throw UnimplementedError('repositoryProvider must be overridden');
});

final initialDataProvider = Provider<AppData>((ref) {
  throw UnimplementedError('initialDataProvider must be overridden');
});

/// Free tier: number of maps without Premium.
const int kFreeMapLimit = 4;

class AppNotifier extends Notifier<AppData> {
  Timer? _saveTimer;

  @override
  AppData build() => ref.read(initialDataProvider);

  // ---------- persistence ----------
  void _set(AppData next) {
    state = next;
    if (kScreenshotMode) return; // never overwrite real data with demo data
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(repositoryProvider).save(state);
    });
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await ref.read(repositoryProvider).save(state);
  }

  // ---------- maps ----------
  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  bool get canAddMap =>
      state.settings.premium || state.maps.length < kFreeMapLimit;

  void addMap(PixMap map) {
    _set(state.copyWith(maps: [...state.maps, map]));
  }

  void updateMap(PixMap map) {
    _set(state.copyWith(
      maps: [for (final m in state.maps) m.id == map.id ? map : m],
    ));
  }

  void deleteMap(String id) {
    final entries = Map<String, Map<String, int>>.from(state.entries)
      ..remove(id);
    _set(state.copyWith(
      maps: state.maps.where((m) => m.id != id).toList(),
      entries: entries,
    ));
  }

  void reorderMaps(int oldIndex, int newIndex) {
    final list = [...state.maps];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _set(state.copyWith(maps: list));
  }

  // ---------- entries ----------
  int? entry(String mapId, DateTime date) =>
      state.entries[mapId]?[Dates.key(date)];

  void setEntry(String mapId, DateTime date, int? level) {
    final all = <String, Map<String, int>>{};
    state.entries.forEach((k, v) => all[k] = Map<String, int>.from(v));
    final inner = all.putIfAbsent(mapId, () => <String, int>{});
    final key = Dates.key(date);
    if (level == null) {
      inner.remove(key);
    } else {
      inner[key] = level;
    }
    _set(state.copyWith(entries: all));
  }

  // ---------- settings ----------
  void updateSettings(Settings Function(Settings) fn) {
    _set(state.copyWith(settings: fn(state.settings)));
  }

  void markCheckinDone(DateTime forDate) {
    updateSettings((s) => s.copyWith(
          lastCheckinDate: Dates.key(Dates.today()),
          checkinCount: s.checkinCount + 1,
        ));
  }

  bool get checkinDoneToday =>
      state.settings.lastCheckinDate == Dates.key(Dates.today());

  /// The day the check-in asks about: yesterday as long as one of the maps
  /// still misses yesterday, otherwise today.
  DateTime get checkinDate {
    final y = Dates.key(Dates.yesterday());
    final missing = state.maps.any((m) => !(state.entries[m.id]?.containsKey(y) ?? false));
    return missing ? Dates.yesterday() : Dates.today();
  }

  /// Marks the check-in as done without counting it (used by the onboarding,
  /// which already logged yesterday).
  void markCheckinDoneQuietly() {
    updateSettings((s) => s.copyWith(lastCheckinDate: Dates.key(Dates.today())));
  }
}

final appProvider = NotifierProvider<AppNotifier, AppData>(AppNotifier.new);

/// Convenience selectors.
final mapsProvider = Provider<List<PixMap>>((ref) => ref.watch(appProvider).maps);
final settingsProvider =
    Provider<Settings>((ref) => ref.watch(appProvider).settings);
final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(settingsProvider).premium);

/// Index of the map currently shown on the home screen.
final selectedMapIndexProvider = StateProvider<int>((ref) => 0);

/// Year shown on the home screen.
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
