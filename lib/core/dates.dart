/// Date helpers. Entries are keyed by `yyyy-MM-dd`.
class Dates {
  Dates._();

  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parse(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime yesterday() => today().subtract(const Duration(days: 1));

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static bool isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  static bool isFuture(DateTime d) => d.isAfter(today());

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns entries of one year as `[month 1..12][day 1..31] -> level or null`.
  static List<List<int?>> yearMatrix(Map<String, int> entries, int year) {
    final m = List.generate(12, (_) => List<int?>.filled(31, null));
    final prefix = '$year-';
    entries.forEach((k, v) {
      if (!k.startsWith(prefix)) return;
      final month = int.parse(k.substring(5, 7));
      final day = int.parse(k.substring(8, 10));
      m[month - 1][day - 1] = v;
    });
    return m;
  }
}
