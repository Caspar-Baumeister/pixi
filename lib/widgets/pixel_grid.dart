import 'dart:math';

import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/pix_map.dart';

/// Soft full-page glow in a map's base colour. Put it as the first child of
/// a full-screen [Stack]; maps themselves sit on a [GridCard] so the glow
/// never tints the cells.
class PageGlow extends StatelessWidget {
  const PageGlow({super.key, required this.color, this.center = const Alignment(-0.15, -0.1)});
  final Color color;
  final Alignment center;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: 1.25,
              colors: [
                color.withValues(alpha: 0.34),
                color.withValues(alpha: 0.16),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Body for a Scaffold with an AppBar: page glow reaching up behind a
/// transparent AppBar. Use with `extendBodyBehindAppBar: true` and
/// `appBar: AppBar(backgroundColor: Colors.transparent, ...)`.
class GlowBody extends StatelessWidget {
  const GlowBody({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageGlow(color: color, center: const Alignment(-0.15, -0.35)),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
          ),
        ),
      ],
    );
  }
}

/// White card with a soft shadow in the map colour, used under every map.
class GridCard extends StatelessWidget {
  const GridCard({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.radius = 18,
  });
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: PixiColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// Portrait year grid: 12 columns (months) × 31 rows (days).
class PixelGrid extends StatelessWidget {
  const PixelGrid({
    super.key,
    required this.map,
    required this.entries,
    required this.year,
    this.onTapDay,
    this.showLabels = true,
    this.glow = false,
    this.gapFactor = 0.18,
    this.highlight,
    this.emptyColor = PixiColors.emptyCell,
    this.futureColor = PixiColors.futureCell,
  });

  final PixMap map;
  final Map<String, int> entries;
  final int year;
  final void Function(DateTime day)? onTapDay;
  final bool showLabels;
  final bool glow;
  final double gapFactor;
  final DateTime? highlight;
  final Color emptyColor;
  final Color futureColor;

  /// Height for a given width (so layouts can reserve space).
  static double heightForWidth(double width, {bool showLabels = true, double gapFactor = 0.18}) {
    final labelW = showLabels ? width * 0.07 : 0.0;
    final cell = (width - labelW) / (12 + 11 * gapFactor);
    final labelH = showLabels ? cell * 1.6 : 0.0;
    return labelH + cell * (31 + 30 * gapFactor);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = heightForWidth(w, showLabels: showLabels, gapFactor: gapFactor);
      final geo = _Geo(w, showLabels: showLabels, gapFactor: gapFactor);
      final matrix = Dates.yearMatrix(entries, year);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapDay == null
            ? null
            : (d) {
                final hit = geo.hitTest(d.localPosition, year);
                if (hit != null) onTapDay!(hit);
              },
        child: CustomPaint(
          size: Size(w, h),
          painter: _GridPainter(
            geo: geo,
            map: map,
            matrix: matrix,
            year: year,
            glow: glow,
            monthLetters: s.monthLetters,
            highlight: highlight,
            emptyColor: emptyColor,
            futureColor: futureColor,
          ),
        ),
      );
    });
  }
}

class _Geo {
  _Geo(this.width, {required this.showLabels, required this.gapFactor}) {
    labelW = showLabels ? width * 0.07 : 0.0;
    cell = (width - labelW) / (12 + 11 * gapFactor);
    gap = cell * gapFactor;
    labelH = showLabels ? cell * 1.6 : 0.0;
  }

  final double width;
  final bool showLabels;
  final double gapFactor;
  late final double labelW;
  late final double cell;
  late final double gap;
  late final double labelH;

  Rect cellRect(int month0, int day0) {
    final x = labelW + month0 * (cell + gap);
    final y = labelH + day0 * (cell + gap);
    return Rect.fromLTWH(x, y, cell, cell);
  }

  DateTime? hitTest(Offset p, int year) {
    final gx = p.dx - labelW;
    final gy = p.dy - labelH;
    if (gx < 0 || gy < 0) return null;
    final m = (gx / (cell + gap)).floor();
    final d = (gy / (cell + gap)).floor();
    if (m < 0 || m > 11 || d < 0 || d > 30) return null;
    if (d + 1 > Dates.daysInMonth(year, m + 1)) return null;
    return DateTime(year, m + 1, d + 1);
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.geo,
    required this.map,
    required this.matrix,
    required this.year,
    required this.glow,
    required this.monthLetters,
    required this.highlight,
    required this.emptyColor,
    required this.futureColor,
  });

  final _Geo geo;
  final PixMap map;
  final List<List<int?>> matrix;
  final int year;
  final bool glow;
  final List<String> monthLetters;
  final DateTime? highlight;
  final Color emptyColor;
  final Color futureColor;

  @override
  void paint(Canvas canvas, Size size) {
    final today = Dates.today();
    final radius = Radius.circular(geo.cell * 0.28);
    final base = map.baseColor;

    // 1. soft radial glow behind everything (ellipse that fades out at the edges)
    if (glow) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1, size.height / size.width);
      final r = size.width * 0.75;
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              base.withValues(alpha: 0.22),
              base.withValues(alpha: 0.08),
              base.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
      );
      canvas.restore();
    }

    // 2. halo behind filled cells (the "leuchten")
    if (glow) {
      final halo = Paint()
        ..color = base.withValues(alpha: 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, geo.cell * 0.9);
      for (var m = 0; m < 12; m++) {
        for (var d = 0; d < 31; d++) {
          final lvl = matrix[m][d];
          if (lvl == null) continue;
          canvas.drawRRect(
              RRect.fromRectAndRadius(geo.cellRect(m, d).inflate(geo.cell * 0.15), radius),
              halo);
        }
      }
    }

    // 3. cells
    final paint = Paint();
    for (var m = 0; m < 12; m++) {
      final days = Dates.daysInMonth(year, m + 1);
      for (var d = 0; d < days; d++) {
        final date = DateTime(year, m + 1, d + 1);
        final lvl = matrix[m][d];
        Color c;
        if (lvl != null && lvl < map.levels.length) {
          c = map.levels[lvl].color;
        } else if (date.isAfter(today)) {
          c = futureColor;
        } else {
          c = emptyColor;
        }
        paint.color = c;
        final rect = geo.cellRect(m, d);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
        if (Dates.sameDay(date, today) && lvl == null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(0.5), radius),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(1, geo.cell * 0.09)
              ..color = PixiColors.ink.withValues(alpha: 0.55),
          );
        }
      }
    }

    // 4. highlight ring
    if (highlight != null && highlight!.year == year) {
      final rect = geo.cellRect(highlight!.month - 1, highlight!.day - 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(geo.cell * 0.22), Radius.circular(geo.cell * 0.4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, geo.cell * 0.14)
          ..color = PixiColors.ink,
      );
    }

    // 5. labels
    if (geo.showLabels) {
      final tpStyle = TextStyle(
        fontFamily: PixiText.body,
        fontSize: max(7, geo.cell * 0.62),
        color: PixiColors.muted,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
      );
      for (var m = 0; m < 12; m++) {
        final tp = TextPainter(
          text: TextSpan(text: monthLetters[m], style: tpStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final r = geo.cellRect(m, 0);
        tp.paint(canvas, Offset(r.center.dx - tp.width / 2, (geo.labelH - tp.height) / 2 - geo.gap));
      }
      for (var d = 0; d < 31; d++) {
        if (d != 0 && (d + 1) % 5 != 0) continue;
        final tp = TextPainter(
          text: TextSpan(text: '${d + 1}', style: tpStyle.copyWith(fontSize: max(6, geo.cell * 0.5))),
          textDirection: TextDirection.ltr,
        )..layout();
        final r = geo.cellRect(0, d);
        tp.paint(canvas, Offset(geo.labelW - tp.width - geo.gap * 2 - 2, r.center.dy - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.matrix != matrix ||
      old.map != map ||
      old.year != year ||
      old.glow != glow ||
      old.highlight != highlight ||
      old.geo.width != geo.width;
}

/// Legend row: coloured dots with labels.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key, required this.map, this.compact = false, this.vertical = false, this.onTap});

  final PixMap map;
  final bool compact;
  final bool vertical;
  final void Function(int level)? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (vertical) {
      // Labels are written out in full: up to two lines, and the font
      // shrinks a little when a single word would not fit the column.
      return LayoutBuilder(builder: (context, c) {
        const chip = 14.0, gap = 7.0;
        final avail = (c.maxWidth.isFinite ? c.maxWidth : 120) - chip - gap;
        var size = 12.0;
        final labels = [for (final l in map.levels) s.r(l.label)];
        for (final label in labels) {
          // Flutter may break after a hyphen, so measure the parts separately.
          for (final word in label.split(RegExp(r'\s+|(?<=-)'))) {
            if (word.isEmpty) continue;
            final tp = TextPainter(
              text: TextSpan(text: word, style: PixiText.label(size: 12)),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            // a little headroom, an exact fit would still wrap on rounding
            if (tp.width > avail * 0.96) size = min(size, 12 * avail * 0.94 / tp.width);
          }
        }
        size = max(8.0, size);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = map.levels.length - 1; i >= 0; i--)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: onTap == null ? null : () => onTap!(i),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Container(
                          width: chip,
                          height: chip,
                          decoration: BoxDecoration(
                            color: map.levels[i].color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [BoxShadow(color: map.baseColor.withValues(alpha: 0.3), blurRadius: 6)],
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: Text(
                          labels[i],
                          maxLines: 2,
                          softWrap: true,
                          style: PixiText.label(size: size, color: PixiColors.inkSoft).copyWith(height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      });
    }
    return Wrap(
      spacing: compact ? 10 : 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < map.levels.length; i++)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 10 : 14,
                  height: compact ? 10 : 14,
                  decoration: BoxDecoration(
                    color: map.levels[i].color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: map.baseColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.r(map.levels[i].label),
                  style: PixiText.label(size: compact ? 11 : 13, color: PixiColors.inkSoft),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
