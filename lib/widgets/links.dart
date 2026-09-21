import 'dart:math';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../models/pix_map.dart';

/// "These two colours belong together": level `la` of map [a] and level `lb`
/// of map [b] show up on the same days far more often than chance.
class LevelLink {
  const LevelLink({
    required this.a,
    required this.la,
    required this.b,
    required this.lb,
    required this.score,
    required this.together,
  });

  final PixMap a;
  final int la;
  final PixMap b;
  final int lb;

  /// 0..1 association strength (phi coefficient of the two "is this level"
  /// indicators, positive only).
  final double score;

  /// Days on which both happened.
  final int together;

  /// 1..3 for the dot display.
  int get strength => score >= 0.45 ? 3 : (score >= 0.28 ? 2 : 1);
}

/// All positive level-to-level links between every pair of maps, strongest
/// first. [entries] maps a map id to its day entries.
List<LevelLink> computeLinks(
  List<PixMap> maps,
  Map<String, Map<String, int>> entries, {
  int minShared = 10,
  int minTogether = 4,
  double minScore = 0.12,
}) {
  final out = <LevelLink>[];
  for (var i = 0; i < maps.length; i++) {
    for (var j = i + 1; j < maps.length; j++) {
      out.addAll(linksBetween(maps[i], entries[maps[i].id] ?? const {}, maps[j], entries[maps[j].id] ?? const {},
          minShared: minShared, minTogether: minTogether, minScore: minScore));
    }
  }
  out.sort((x, y) => y.score.compareTo(x.score));
  return out;
}

List<LevelLink> linksBetween(
  PixMap a,
  Map<String, int> ea,
  PixMap b,
  Map<String, int> eb, {
  int minShared = 10,
  int minTogether = 4,
  double minScore = 0.12,
}) {
  final na = a.levels.length, nb = b.levels.length;
  final ca = List<int>.filled(na, 0), cb = List<int>.filled(nb, 0);
  final cab = List.generate(na, (_) => List<int>.filled(nb, 0));
  var n = 0;
  ea.forEach((k, va) {
    final vb = eb[k];
    if (vb == null) return;
    final x = va.clamp(0, na - 1), y = vb.clamp(0, nb - 1);
    ca[x]++;
    cb[y]++;
    cab[x][y]++;
    n++;
  });
  if (n < minShared) return const [];
  final res = <LevelLink>[];
  for (var x = 0; x < na; x++) {
    for (var y = 0; y < nb; y++) {
      final c = cab[x][y];
      if (c < minTogether) continue;
      final denom = sqrt(ca[x] * (n - ca[x]) * cb[y] * (n - cb[y]).toDouble());
      if (denom == 0) continue;
      final phi = (c * n - ca[x] * cb[y]) / denom;
      if (phi < minScore) continue;
      res.add(LevelLink(a: a, la: x, b: b, lb: y, score: phi.clamp(0.0, 1.0), together: c));
    }
  }
  res.sort((p, q) => q.score.compareTo(p.score));
  return res;
}

/// One link: colour chip + label ⟷ colour chip + label, with 1–3 dots for
/// the strength. No numbers.
class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.link, this.showMaps = true});
  final LevelLink link;
  final bool showMaps;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ca = link.a.levels[link.la].color;
    final cb = link.b.levels[link.lb].color;
    Widget side(PixMap m, int l, Color c, CrossAxisAlignment align) => Expanded(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(s.r(m.levels[l].label),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: PixiText.label(size: 13, color: PixiColors.ink)),
              if (showMaps)
                Text(s.r(m.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: PixiText.label(size: 11)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          side(link.a, link.la, ca, CrossAxisAlignment.end),
          const SizedBox(width: 10),
          _Dot(color: ca),
          SizedBox(
            width: 54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(colors: [ca, cb]),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < link.strength ? PixiColors.ink : PixiColors.line,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _Dot(color: cb),
          const SizedBox(width: 10),
          side(link.b, link.lb, cb, CrossAxisAlignment.start),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10)],
        ),
      );
}
