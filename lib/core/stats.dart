import 'dart:math';

import 'dates.dart';
import '../models/pix_map.dart';

class MapStats {
  MapStats({
    required this.count,
    required this.average,
    required this.monthAverages,
    required this.weekdayAverages,
    required this.distribution,
    required this.streak,
  });

  final int count;

  /// Average level index (0..levels-1), null if no data.
  final double? average;

  /// 12 entries, null when no data in that month.
  final List<double?> monthAverages;

  /// 7 entries (Mon..Sun), null when no data.
  final List<double?> weekdayAverages;

  /// Count per level index.
  final List<int> distribution;

  /// Consecutive days logged, ending today or yesterday.
  final int streak;

  int? get bestMonth => _argmax(monthAverages);
  int? get worstMonth => _argmin(monthAverages);
  int? get bestWeekday => _argmax(weekdayAverages);
  int? get worstWeekday => _argmin(weekdayAverages);

  static int? _argmax(List<double?> l) {
    int? idx;
    for (var i = 0; i < l.length; i++) {
      final v = l[i];
      if (v == null) continue;
      if (idx == null || v > l[idx]!) idx = i;
    }
    return idx;
  }

  static int? _argmin(List<double?> l) {
    int? idx;
    for (var i = 0; i < l.length; i++) {
      final v = l[i];
      if (v == null) continue;
      if (idx == null || v < l[idx]!) idx = i;
    }
    return idx;
  }
}

MapStats computeStats(PixMap map, Map<String, int> entries, int year) {
  final levels = map.levels.length;
  final dist = List<int>.filled(levels, 0);
  final monthSum = List<double>.filled(12, 0);
  final monthN = List<int>.filled(12, 0);
  final wdSum = List<double>.filled(7, 0);
  final wdN = List<int>.filled(7, 0);
  var total = 0.0;
  var n = 0;

  entries.forEach((k, v) {
    if (!k.startsWith('$year-')) return;
    final d = Dates.parse(k);
    final lvl = v.clamp(0, levels - 1);
    dist[lvl]++;
    total += lvl;
    n++;
    monthSum[d.month - 1] += lvl;
    monthN[d.month - 1]++;
    wdSum[d.weekday - 1] += lvl;
    wdN[d.weekday - 1]++;
  });

  // streak
  var streak = 0;
  var cursor = Dates.today();
  if (!entries.containsKey(Dates.key(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  while (entries.containsKey(Dates.key(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return MapStats(
    count: n,
    average: n == 0 ? null : total / n,
    monthAverages: List.generate(
        12, (i) => monthN[i] == 0 ? null : monthSum[i] / monthN[i]),
    weekdayAverages:
        List.generate(7, (i) => wdN[i] == 0 ? null : wdSum[i] / wdN[i]),
    distribution: dist,
    streak: streak,
  );
}

class Correlation {
  Correlation({required this.sharedDays, required this.r, required this.diff});

  final int sharedDays;

  /// Pearson correlation of normalised levels, null if not computable.
  final double? r;

  /// Average level of B on "high A" days minus on "low A" days (in B levels).
  final double? diff;

  bool get meaningful => sharedDays >= 10 && r != null && r!.abs() >= 0.2;
}

Correlation correlate(
  PixMap a,
  Map<String, int> ea,
  PixMap b,
  Map<String, int> eb,
) {
  final xs = <double>[];
  final ys = <double>[];
  final rawB = <double>[];
  final la = max(1, a.levels.length - 1).toDouble();
  final lb = max(1, b.levels.length - 1).toDouble();
  ea.forEach((k, va) {
    final vb = eb[k];
    if (vb == null) return;
    xs.add(va / la);
    ys.add(vb / lb);
    rawB.add(vb.toDouble());
  });
  final n = xs.length;
  if (n < 3) return Correlation(sharedDays: n, r: null, diff: null);

  final mx = xs.reduce((p, q) => p + q) / n;
  final my = ys.reduce((p, q) => p + q) / n;
  var sxy = 0.0, sxx = 0.0, syy = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (xs[i] - mx) * (ys[i] - my);
    sxx += (xs[i] - mx) * (xs[i] - mx);
    syy += (ys[i] - my) * (ys[i] - my);
  }
  final denom = sqrt(sxx * syy);
  final r = denom == 0 ? null : sxy / denom;

  // high/low split of A around its mean
  var hiSum = 0.0, hiN = 0, loSum = 0.0, loN = 0;
  for (var i = 0; i < n; i++) {
    if (xs[i] >= mx) {
      hiSum += rawB[i];
      hiN++;
    } else {
      loSum += rawB[i];
      loN++;
    }
  }
  final diff = (hiN == 0 || loN == 0) ? null : hiSum / hiN - loSum / loN;
  return Correlation(sharedDays: n, r: r, diff: diff);
}

/// How often each level was logged in one month, plus the change against the
/// month before. Index matches `map.levels`.
class MonthColors {
  MonthColors({
    required this.year,
    required this.month,
    required this.counts,
    required this.previous,
  });

  final int year;
  final int month;
  final List<int> counts;
  final List<int> previous;

  int get total => counts.fold(0, (a, b) => a + b);
  int get previousTotal => previous.fold(0, (a, b) => a + b);

  /// counts[i] - previous[i]
  int delta(int i) => counts[i] - previous[i];

  /// Level logged most often this month, null when the month is empty.
  int? get top {
    int? idx;
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] == 0) continue;
      if (idx == null || counts[i] > counts[idx]) idx = i;
    }
    return idx;
  }

  /// Biggest change against last month (by absolute value), null if flat.
  int? get biggestMove {
    int? idx;
    for (var i = 0; i < counts.length; i++) {
      if (delta(i) == 0) continue;
      if (idx == null || delta(i).abs() > delta(idx).abs()) idx = i;
    }
    return idx;
  }
}

MonthColors monthColors(PixMap map, Map<String, int> entries, int year, int month) {
  final levels = map.levels.length;
  final now = List<int>.filled(levels, 0);
  final prev = List<int>.filled(levels, 0);
  final pm = month == 1 ? 12 : month - 1;
  final py = month == 1 ? year - 1 : year;

  entries.forEach((k, v) {
    final d = Dates.parse(k);
    final lvl = v.clamp(0, levels - 1);
    if (d.year == year && d.month == month) now[lvl]++;
    if (d.year == py && d.month == pm) prev[lvl]++;
  });

  return MonthColors(year: year, month: month, counts: now, previous: prev);
}
