import 'dart:math';

import 'dates.dart';
import '../models/pix_map.dart';

/// Plausible demo entries for onboarding previews (deterministic).
class DemoData {
  DemoData._();

  static final Map<String, Map<String, int>> _cache = {};

  /// Entries from Jan 1 of [year] up to today (or the whole year when
  /// [fullYear] is true), for a map with `levels` levels.
  static Map<String, int> forTemplate(
    String templateId,
    int levels, {
    int? year,
    bool fullYear = false,
  }) {
    final y = year ?? DateTime.now().year;
    final key = '$templateId-$levels-$y-$fullYear';
    return _cache.putIfAbsent(key, () => _generate(templateId, levels, y, fullYear));
  }

  /// Preview for carousels: up to today, or the whole year early in the year
  /// so the card never looks empty.
  static Map<String, int> preview(String templateId, int levels) {
    final now = DateTime.now();
    final doy = now.difference(DateTime(now.year, 1, 1)).inDays;
    return forTemplate(templateId, levels, fullYear: doy < 150);
  }

  static Map<String, int> _generate(String id, int levels, int y, bool full) {
    final rnd = Random(id.hashCode ^ y);
    final out = <String, int>{};
    final end = full ? DateTime(y, 12, 31) : Dates.today();
    var d = DateTime(y, 1, 1);
    var mood = 0.55; // slow-moving baseline 0..1
    while (!d.isAfter(end)) {
      // seasonality: brighter in summer, a dip in Feb/Nov
      final season = 0.12 * sin((d.month - 4) / 12 * 2 * pi);
      mood += (rnd.nextDouble() - 0.5) * 0.18;
      mood = mood.clamp(0.15, 0.95);
      var v = mood + season;
      switch (id) {
        case 'mood':
          if (d.weekday >= 6) v += 0.12; // weekends
          if (d.weekday == 1) v -= 0.08;
          break;
        case 'dreams':
          v = rnd.nextDouble() * 0.9 + (d.weekday >= 6 ? 0.1 : 0);
          break;
        case 'sleep':
          v = 0.55 + (rnd.nextDouble() - 0.5) * 0.7 + (d.weekday >= 5 ? -0.1 : 0);
          break;
        case 'training':
          // ~3 sessions a week, harder ones mid-week
          final on = rnd.nextDouble() < (d.weekday == 2 || d.weekday == 4 || d.weekday == 6 ? 0.8 : 0.2);
          v = on ? (rnd.nextDouble() < 0.4 ? 1.0 : 0.6) : 0.0;
          break;
        case 'cry':
          v = rnd.nextDouble() < 0.12 ? (rnd.nextDouble() < 0.3 ? 1.0 : 0.5) : 0.0;
          break;
        default:
          v = rnd.nextDouble();
      }
      final lvl = (v.clamp(0.0, 0.999) * levels).floor();
      // leave a few gaps so it looks human
      if (rnd.nextDouble() > 0.04) out[Dates.key(d)] = lvl;
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  /// Sleep demo correlated with the given mood demo (for the correlation
  /// preview): good nights tend to precede good days.
  static Map<String, int> correlatedWith(Map<String, int> primary, int primaryLevels, int levels) {
    final rnd = Random(42);
    final out = <String, int>{};
    primary.forEach((k, v) {
      final base = v / max(1, primaryLevels - 1);
      final noisy = (base * 0.7 + rnd.nextDouble() * 0.3).clamp(0.0, 0.999);
      out[k] = (noisy * levels).floor();
    });
    return out;
  }
}
