import 'dart:math';

import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/pix_map.dart';
import 'pixi_cat.dart';

/// The year as a wheel, modelled on the calendar poster: 12 wedges, each a
/// mosaic of day cells growing from the centre outwards, month names on the
/// outer ring, a dotted ring, and Pixi sitting in the middle.
class CircleYear extends StatelessWidget {
  const CircleYear({
    super.key,
    required this.map,
    required this.entries,
    required this.year,
    this.size = 340,
    this.showNumbers = true,
    this.showCat = true,
    this.animateCat = true,
    this.onTapDay,
  });

  final PixMap map;
  final Map<String, int> entries;
  final int year;
  final double size;
  final bool showNumbers;
  final bool showCat;
  final bool animateCat;
  final void Function(DateTime day)? onTapDay;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final layout = _WheelLayout.forSize(size, year);
    final matrix = Dates.yearMatrix(entries, year);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onTapDay == null
                ? null
                : (d) {
                    final hit = layout.hitTest(d.localPosition);
                    if (hit != null) onTapDay!(hit);
                  },
            child: CustomPaint(
              size: Size(size, size),
              painter: _WheelPainter(
                layout: layout,
                map: map,
                matrix: matrix,
                year: year,
                months: s.monthsLong.map((m) => m.toUpperCase()).toList(),
                showNumbers: showNumbers && size >= 280,
              ),
            ),
          ),
          if (showCat)
            PixiCat(size: layout.rIn * 1.7, animate: animateCat, catId: map.catId),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Geometry (cached per size/year)
// ---------------------------------------------------------------------------

class _Cell {
  _Cell(this.month, this.day, this.poly, this.seed);
  final int month; // 1..12
  final int day; // 1..
  final List<Offset> poly;
  final Offset seed;
}

class _WheelLayout {
  _WheelLayout._(this.size, this.year);

  static final Map<String, _WheelLayout> _cache = {};

  static _WheelLayout forSize(double size, int year) {
    final key = '${size.toStringAsFixed(1)}-$year';
    return _cache.putIfAbsent(key, () => _WheelLayout._(size, year).._build());
  }

  final double size;
  final int year;

  late final Offset c;
  late final double rOuter; // outer border
  late final double rDots; // dotted ring
  late final double rTextOut; // month band outer
  late final double rTextIn; // month band inner = mosaic outer
  late final double rIn; // centre circle
  final List<_Cell> cells = [];

  static const double _startAngle = -pi / 2 - pi / 12; // January centred at top

  void _build() {
    c = Offset(size / 2, size / 2);
    rOuter = size * 0.485;
    rDots = size * 0.462;
    rTextOut = size * 0.445;
    rTextIn = size * 0.395;
    rIn = size * 0.135;

    for (var m = 1; m <= 12; m++) {
      final a0 = _startAngle + (m - 1) * pi / 6;
      final a1 = a0 + pi / 6;
      final days = Dates.daysInMonth(year, m);
      final rows = _rowsFor(days);
      final seeds = <Offset>[];
      final rnd = _Rng(year * 31 + m * 7);
      final rowH = (rTextIn - rIn) / rows.length;
      var day = 0;
      for (var r = 0; r < rows.length; r++) {
        final n = rows[r];
        final rad = rIn + rowH * (r + 0.5);
        for (var k = 0; k < n; k++) {
          final t = (k + 0.5) / n;
          final ang = a0 + (a1 - a0) * t;
          final jr = (rnd.next() - 0.5) * rowH * 0.55;
          final ja = (rnd.next() - 0.5) * (a1 - a0) / n * 0.55;
          seeds.add(Offset(
            c.dx + (rad + jr) * cos(ang + ja),
            c.dy + (rad + jr) * sin(ang + ja),
          ));
          day++;
        }
      }
      assert(day == days);

      final wedge = _wedgePolygon(a0, a1, rIn, rTextIn);
      for (var i = 0; i < seeds.length; i++) {
        var poly = wedge;
        for (var j = 0; j < seeds.length; j++) {
          if (i == j) continue;
          poly = _clipHalfPlane(poly, seeds[i], seeds[j]);
          if (poly.length < 3) break;
        }
        cells.add(_Cell(m, i + 1, poly, seeds[i]));
      }
    }
  }

  static List<int> _rowsFor(int days) {
    switch (days) {
      case 31:
        return const [2, 3, 3, 4, 4, 4, 4, 4, 3];
      case 30:
        return const [2, 3, 3, 4, 4, 4, 4, 3, 3];
      case 29:
        return const [2, 3, 3, 3, 4, 4, 4, 3, 3];
      default:
        return const [2, 3, 3, 3, 4, 4, 3, 3, 3];
    }
  }

  List<Offset> _wedgePolygon(double a0, double a1, double r0, double r1) {
    const seg = 10;
    final pts = <Offset>[];
    for (var i = 0; i <= seg; i++) {
      final a = a0 + (a1 - a0) * i / seg;
      pts.add(Offset(c.dx + r0 * cos(a), c.dy + r0 * sin(a)));
    }
    for (var i = seg; i >= 0; i--) {
      final a = a0 + (a1 - a0) * i / seg;
      pts.add(Offset(c.dx + r1 * cos(a), c.dy + r1 * sin(a)));
    }
    return pts;
  }

  /// Keep the part of [poly] closer to [a] than to [b].
  static List<Offset> _clipHalfPlane(List<Offset> poly, Offset a, Offset b) {
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final n = Offset(b.dx - a.dx, b.dy - a.dy); // normal pointing to b
    double side(Offset p) => (p.dx - mid.dx) * n.dx + (p.dy - mid.dy) * n.dy;

    final out = <Offset>[];
    for (var i = 0; i < poly.length; i++) {
      final cur = poly[i];
      final prev = poly[(i - 1 + poly.length) % poly.length];
      final sc = side(cur);
      final sp = side(prev);
      final curIn = sc <= 0;
      final prevIn = sp <= 0;
      if (curIn) {
        if (!prevIn) out.add(_intersect(prev, cur, sp, sc));
        out.add(cur);
      } else if (prevIn) {
        out.add(_intersect(prev, cur, sp, sc));
      }
    }
    return out;
  }

  static Offset _intersect(Offset p, Offset q, double sp, double sq) {
    final t = sp / (sp - sq);
    return Offset(p.dx + (q.dx - p.dx) * t, p.dy + (q.dy - p.dy) * t);
  }

  DateTime? hitTest(Offset p) {
    final d = (p - c).distance;
    if (d < rIn || d > rTextIn) return null;
    var ang = atan2(p.dy - c.dy, p.dx - c.dx) - _startAngle;
    while (ang < 0) {
      ang += 2 * pi;
    }
    final month = (ang / (pi / 6)).floor() + 1;
    _Cell? best;
    var bestD = double.infinity;
    for (final cell in cells) {
      if (cell.month != month) continue;
      final dd = (cell.seed - p).distanceSquared;
      if (dd < bestD) {
        bestD = dd;
        best = cell;
      }
    }
    if (best == null) return null;
    return DateTime(year, best.month, best.day);
  }
}

class _Rng {
  _Rng(int seed) : _s = seed & 0x7fffffff;
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.layout,
    required this.map,
    required this.matrix,
    required this.year,
    required this.months,
    required this.showNumbers,
  });

  final _WheelLayout layout;
  final PixMap map;
  final List<List<int?>> matrix;
  final int year;
  final List<String> months;
  final bool showNumbers;

  @override
  void paint(Canvas canvas, Size size) {
    final c = layout.c;
    final base = map.baseColor;
    final today = Dates.today();
    final ink = PixiColors.ink;

    // --- glow: base colour radiating from the centre ("Kreis hinten beleuchtet")
    canvas.drawCircle(
      c,
      layout.rOuter,
      Paint()
        ..shader = RadialGradient(
          colors: [
            base.withValues(alpha: 0.55),
            base.withValues(alpha: 0.22),
            base.withValues(alpha: 0.05),
            base.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.25, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: layout.rOuter)),
    );

    // --- mosaic cells
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.5, size.width / 520)
      ..strokeJoin = StrokeJoin.round
      ..color = ink.withValues(alpha: 0.62);
    final numStyle = TextStyle(
      fontFamily: PixiText.body,
      fontSize: max(5.5, size.width / 62),
      color: ink.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 600)],
    );
    final numStyleLight = numStyle.copyWith(color: Colors.white.withValues(alpha: 0.9));

    for (final cell in layout.cells) {
      if (cell.poly.length < 3) continue;
      final path = Path()..addPolygon(cell.poly, true);
      final lvl = matrix[cell.month - 1][cell.day - 1];
      final date = DateTime(year, cell.month, cell.day);
      Color col;
      if (lvl != null && lvl < map.levels.length) {
        col = map.levels[lvl].color;
      } else if (date.isAfter(today)) {
        col = Colors.white.withValues(alpha: 0.55);
      } else {
        col = Colors.white.withValues(alpha: 0.9);
      }
      fill.color = col;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);

      if (showNumbers) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${cell.day}',
            style: (lvl != null && col.isDark) ? numStyleLight : numStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final centroid = _centroid(cell.poly);
        tp.paint(canvas, centroid - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // --- wedge separators & ring lines
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.6, size.width / 480)
      ..color = ink.withValues(alpha: 0.8);
    for (var m = 0; m < 12; m++) {
      final a = _WheelLayout._startAngle + m * pi / 6;
      canvas.drawLine(
        Offset(c.dx + layout.rIn * cos(a), c.dy + layout.rIn * sin(a)),
        Offset(c.dx + layout.rTextIn * cos(a), c.dy + layout.rTextIn * sin(a)),
        thin,
      );
    }
    canvas.drawCircle(c, layout.rTextIn, thin);
    canvas.drawCircle(c, layout.rTextOut, thin..strokeWidth = max(0.5, size.width / 600));
    canvas.drawCircle(c, layout.rOuter, thin..strokeWidth = max(0.8, size.width / 400));

    // --- dotted ring
    final dot = Paint()..color = ink.withValues(alpha: 0.75);
    final dotR = max(0.6, size.width / 380);
    final dotCount = 144;
    for (var i = 0; i < dotCount; i++) {
      final a = i * 2 * pi / dotCount;
      canvas.drawCircle(
        Offset(c.dx + layout.rDots * cos(a), c.dy + layout.rDots * sin(a)),
        dotR,
        dot,
      );
    }

    // --- month names along the band
    final monthStyle = TextStyle(
      fontFamily: PixiText.display,
      fontSize: max(6, size.width / 34),
      letterSpacing: size.width / 300,
      color: ink,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation('wght', 500)],
    );
    final rText = (layout.rTextOut + layout.rTextIn) / 2;
    for (var m = 0; m < 12; m++) {
      final centerA = _WheelLayout._startAngle + (m + 0.5) * pi / 6;
      _drawArcText(canvas, months[m], c, rText, centerA, monthStyle);
      // small separator dots between months on the band
      final sepA = _WheelLayout._startAngle + m * pi / 6;
      canvas.drawCircle(
        Offset(c.dx + rText * cos(sepA), c.dy + rText * sin(sepA)),
        dotR * 1.2,
        dot,
      );
    }

    // --- centre disc for the cat
    canvas.drawCircle(
      c,
      layout.rIn,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.6),
            base.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: layout.rIn)),
    );
    canvas.drawCircle(c, layout.rIn, thin..strokeWidth = max(0.6, size.width / 480));

    // tiny stars around the centre like the poster
    final star = Paint()..color = ink.withValues(alpha: 0.7);
    final rnd = _Rng(year);
    for (var i = 0; i < 14; i++) {
      final a = rnd.next() * 2 * pi;
      final r = layout.rIn * (1.05 + rnd.next() * 0.25);
      final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      final s = dotR * (0.8 + rnd.next() * 1.4);
      canvas.drawLine(p - Offset(s * 1.6, 0), p + Offset(s * 1.6, 0), star..strokeWidth = 0.7);
      canvas.drawLine(p - Offset(0, s * 1.6), p + Offset(0, s * 1.6), star);
    }
  }

  /// Draws [text] centred at [centerAngle] along a circle, letters upright
  /// with their top facing outwards (like the poster).
  void _drawArcText(Canvas canvas, String text, Offset c, double r,
      double centerAngle, TextStyle style) {
    final painters = <TextPainter>[];
    var total = 0.0;
    for (final ch in text.characters) {
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(tp);
      total += tp.width;
    }
    final totalAngle = total / r;
    var a = centerAngle - totalAngle / 2;
    for (final tp in painters) {
      final half = tp.width / 2 / r;
      final mid = a + half;
      canvas.save();
      canvas.translate(c.dx + r * cos(mid), c.dy + r * sin(mid));
      canvas.rotate(mid + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
      a += half * 2;
    }
  }

  static Offset _centroid(List<Offset> poly) {
    var x = 0.0, y = 0.0, area = 0.0;
    for (var i = 0; i < poly.length; i++) {
      final p = poly[i];
      final q = poly[(i + 1) % poly.length];
      final cross = p.dx * q.dy - q.dx * p.dy;
      area += cross;
      x += (p.dx + q.dx) * cross;
      y += (p.dy + q.dy) * cross;
    }
    if (area.abs() < 1e-6) {
      return poly.reduce((a, b) => a + b) / poly.length.toDouble();
    }
    area *= 0.5;
    return Offset(x / (6 * area), y / (6 * area));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.matrix != matrix ||
      old.map != map ||
      old.year != year ||
      old.layout != layout ||
      old.showNumbers != showNumbers;
}
