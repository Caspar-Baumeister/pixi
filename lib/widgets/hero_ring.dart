import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/templates.dart';

/// The big tile ring of the very first onboarding screen: a frame of glossy
/// pixels around the whole screen that slowly turns and glides from one
/// colour set to the next (purple, night blue, green …). [child] sits in the
/// light disc in the middle.
class HeroRing extends StatefulWidget {
  const HeroRing({
    super.key,
    required this.templates,
    this.child,
    this.hold = const Duration(milliseconds: 2600),
    this.fade = const Duration(milliseconds: 1800),
    this.turn = const Duration(seconds: 110),
    this.centerY = 0.46,
    this.innerRadius = 0.475,
  });

  /// Colour sets, in this order (their level colours become the tiles).
  final List<MapTemplate> templates;
  final Widget? child;
  final Duration hold;
  final Duration fade;

  /// One full rotation.
  final Duration turn;

  /// Centre of the ring as a fraction of the height.
  final double centerY;

  /// Radius of the light disc as a fraction of the width.
  final double innerRadius;

  @override
  State<HeroRing> createState() => _HeroRingState();
}

class _HeroRingState extends State<HeroRing> with TickerProviderStateMixin {
  late final AnimationController _cycle;
  late final AnimationController _spin;
  late final List<_Set> _sets;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _sets = [for (final t in widget.templates) _Set.of(t)];
    _cycle = AnimationController(vsync: this, duration: widget.hold + widget.fade)
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) {
          setState(() => _index = (_index + 1) % _sets.length);
          _cycle.forward(from: 0);
        }
      })
      ..forward();
    _spin = AnimationController(vsync: this, duration: widget.turn)..repeat();
  }

  @override
  void dispose() {
    _cycle.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// 0 while holding, then 0..1 over the fade.
  double get _t {
    final holdFrac = widget.hold.inMilliseconds / (widget.hold + widget.fade).inMilliseconds;
    final v = _cycle.value;
    if (v <= holdFrac) return 0;
    return (v - holdFrac) / (1 - holdFrac);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final center = Offset(w / 2, h * widget.centerY);
      final r0 = w * widget.innerRadius;
      var rMax = 0.0;
      for (final p in [Offset.zero, Offset(w, 0), Offset(0, h), Offset(w, h)]) {
        rMax = max(rMax, (p - center).distance);
      }
      rMax += 30;
      final geo = _RingGeo.of(r0, rMax);
      final from = _sets[_index];
      final to = _sets[(_index + 1) % _sets.length];

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // grout + light disc
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _cycle,
              builder: (_, __) => CustomPaint(
                painter: _BackPainter(center: center, r0: r0, base: _Set.lerpBase(from, to, _eased(_t))),
              ),
            ),
          ),
          // the turning tiles (repainted only while the colours change)
          Positioned(
            left: center.dx - rMax,
            top: center.dy - rMax,
            width: rMax * 2,
            height: rMax * 2,
            child: AnimatedBuilder(
              animation: _spin,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _cycle,
                  builder: (_, __) => CustomPaint(
                    size: Size.square(rMax * 2),
                    painter: _TilesPainter(geo: geo, from: from, to: to, t: _t),
                  ),
                ),
              ),
              builder: (_, child) => Transform.rotate(angle: _spin.value * 2 * pi, child: child),
            ),
          ),
          // soft light where disc and tiles meet
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _EdgeGlowPainter(center: center, r0: r0)),
            ),
          ),
          if (widget.child != null)
            Positioned(
              left: center.dx - r0,
              top: center.dy - r0,
              width: r0 * 2,
              height: r0 * 2,
              child: Center(child: widget.child),
            ),
        ],
      );
    });
  }
}

double _eased(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

/// One colour set: the template's level colours without the near-white ones.
class _Set {
  _Set(this.base, this.palette);
  final Color base;
  final List<Color> palette;

  static _Set of(MapTemplate t) {
    var cols = [for (final l in t.levels) l.color].where((c) => c.computeLuminance() < 0.8).toList();
    if (cols.length < 3) {
      cols = [...cols, t.baseColor, Color.lerp(t.baseColor, Colors.white, 0.35)!];
    }
    return _Set(t.baseColor, cols);
  }

  static Color lerpBase(_Set a, _Set b, double t) => Color.lerp(a.base, b.base, t)!;

  Color pick(double s1, double s2) {
    final c = palette[(s1 * palette.length).floor().clamp(0, palette.length - 1)];
    // a little light / shade variation per tile
    return s2 >= 0.5
        ? Color.lerp(c, Colors.white, (s2 - 0.5) * 0.45)!
        : Color.lerp(c, Colors.black, (0.5 - s2) * 0.22)!;
  }
}

class _Tile {
  _Tile(this.angle, this.rc, this.dr, this.dt, this.s1, this.s2, this.sweep);
  final double angle; // centre angle
  final double rc; // centre radius
  final double dr; // radial size
  final double dt; // tangential size
  final double s1, s2; // colour seeds
  final double sweep; // 0..1 when this tile changes colour during a fade
}

class _RingGeo {
  _RingGeo._(this.r0, this.rMax);
  final double r0;
  final double rMax;
  final List<_Tile> tiles = [];

  static final Map<String, _RingGeo> _cache = {};

  static _RingGeo of(double r0, double rMax) {
    final key = '${r0.toStringAsFixed(1)}-${rMax.toStringAsFixed(1)}';
    return _cache.putIfAbsent(key, () => _RingGeo._(r0, rMax).._build());
  }

  void _build() {
    final rnd = Random(7);
    var r = r0 + 2;
    var ring = 0;
    while (r < rMax) {
      final d = max(14.0, r * 0.105);
      final rc = r + d / 2;
      final n = max(12, (2 * pi * rc / (d * 1.08)).round());
      final step = 2 * pi / n;
      final phase = rnd.nextDouble() * step;
      for (var i = 0; i < n; i++) {
        final a = phase + i * step;
        final norm = (a / (2 * pi)) % 1.0;
        tiles.add(_Tile(
          a,
          rc,
          d * 0.9,
          2 * pi * rc / n * 0.88,
          rnd.nextDouble(),
          rnd.nextDouble(),
          (norm * 0.85 + ring * 0.015 + rnd.nextDouble() * 0.06) % 1.0,
        ));
      }
      r += d;
      ring++;
    }
  }
}

class _TilesPainter extends CustomPainter {
  _TilesPainter({required this.geo, required this.from, required this.to, required this.t});
  final _RingGeo geo;
  final _Set from;
  final _Set to;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final fill = Paint()..style = PaintingStyle.fill;
    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.2);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const spread = 0.9;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    for (final tile in geo.tiles) {
      final local = _eased(t * (1 + spread) - tile.sweep * spread);
      final a = from.pick(tile.s1, tile.s2);
      final b = to.pick(tile.s1, tile.s2);
      final col = local <= 0 ? a : (local >= 1 ? b : Color.lerp(a, b, local)!);
      canvas.save();
      canvas.rotate(tile.angle);
      final rect = Rect.fromCenter(center: Offset(tile.rc, 0), width: tile.dr, height: tile.dt);
      final rad = Radius.circular(min(tile.dr, tile.dt) * 0.22);
      fill.color = col;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, rad), fill);
      // lighter half towards the bright centre: reads like a glossy bevel
      final g = Rect.fromLTWH(rect.left + tile.dr * 0.08, rect.top + tile.dt * 0.1, tile.dr * 0.42, tile.dt * 0.8);
      canvas.drawRRect(RRect.fromRectAndRadius(g, rad * 0.8), gloss);
      edge.color = Color.lerp(col, Colors.black, 0.28)!.withValues(alpha: 0.45);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, rad), edge);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TilesPainter old) =>
      old.t != t || old.from != from || old.to != to || old.geo != geo;
}

class _BackPainter extends CustomPainter {
  _BackPainter({required this.center, required this.r0, required this.base});
  final Offset center;
  final double r0;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    // grout between the tiles
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.lerp(base, Colors.white, 0.35)!);
    // the light disc, tinted with the current set
    canvas.drawCircle(
      center,
      r0 + 1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(PixiColors.paper, base, 0.08)!,
            Color.lerp(PixiColors.paper, base, 0.14)!,
            Color.lerp(PixiColors.paper, base, 0.24)!,
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r0 + 1)),
    );
  }

  @override
  bool shouldRepaint(covariant _BackPainter old) => old.base != base || old.center != center || old.r0 != r0;
}

class _EdgeGlowPainter extends CustomPainter {
  _EdgeGlowPainter({required this.center, required this.r0});
  final Offset center;
  final double r0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      center,
      r0 + 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  @override
  bool shouldRepaint(covariant _EdgeGlowPainter old) => old.center != center || old.r0 != r0;
}
