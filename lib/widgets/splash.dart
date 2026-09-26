import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Background of the native launch screen (LaunchScreen.storyboard uses the
/// same colour, so the hand-over is invisible).
const Color kSplashBackground = Color(0xFFEFEBFA);

/// Cat of the native launch screen: same asset, same size, same place.
const String kSplashCat = 'assets/cats/wave_still.png';
const double kSplashCatSize = 200;

/// Splash on every cold start: lilac paper, a frame of pixels building up
/// around the screen edge, Pixi in the middle. Then it fades into the app.
class PixiSplash extends StatefulWidget {
  const PixiSplash({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<PixiSplash> createState() => _PixiSplashState();
}

class _PixiSplashState extends State<PixiSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Keep the native launch screen until the cat is decoded, so the first
    // Flutter frame looks exactly like it.
    WidgetsBinding.instance.deferFirstFrame();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) widget.onDone();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    precacheImage(const AssetImage(kSplashCat), context).whenComplete(() {
      WidgetsBinding.instance.allowFirstFrame();
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final fadeOut = ((v - 0.82) / 0.18).clamp(0.0, 1.0);
        final glow = Curves.easeOut.transform((v / 0.3).clamp(0.0, 1.0));
        final word = Curves.easeOut.transform(((v - 0.25) / 0.2).clamp(0.0, 1.0));
        return IgnorePointer(
          ignoring: fadeOut > 0.5,
          child: Opacity(
            opacity: 1 - Curves.easeIn.transform(fadeOut),
            child: ColoredBox(
              color: kSplashBackground,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: glow,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.8,
                          colors: [Color(0x55B9A4F0), Color(0x00B9A4F0)],
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(painter: _FramePainter(progress: (v / 0.62).clamp(0.0, 1.0))),
                  Center(
                    child: Image.asset(kSplashCat, width: kSplashCatSize, height: kSplashCatSize, fit: BoxFit.contain),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.34),
                    child: Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - word)),
                        child: Text('Pixi', style: PixiText.title(size: 40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Two rows of glossy lilac tiles following the rounded screen edge. Tiles
/// pop in one after another, clockwise from the top.
class _FramePainter extends CustomPainter {
  _FramePainter({required this.progress});
  final double progress;

  static const _palette = [
    Color(0xFF9A7BE3),
    Color(0xFFCBC2EC),
    Color(0xFFE4A3D6),
    Color(0xFF8A86B3),
    Color(0xFFB9A4F0),
    Color(0xFF7B63D1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 24.0;
    const gap = 4.0;
    final rnd = Random(3);
    final fill = Paint();
    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var row = 0; row < 2; row++) {
      final inset = -4 + row * (tile + gap) + tile / 2;
      final rect = (Offset.zero & size).deflate(inset);
      final radius = max(8.0, 54.0 - inset);
      final pts = _alongRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), tile + gap);
      for (var i = 0; i < pts.length; i++) {
        final (pos, ang, frac) = pts[i];
        final col = _palette[rnd.nextInt(_palette.length)];
        final shade = rnd.nextDouble();
        final appear = ((progress * 1.25) - frac - row * 0.08).clamp(0.0, 0.25) / 0.25;
        if (appear <= 0) continue;
        final s = Curves.easeOutBack.transform(appear);
        final c = shade > 0.5
            ? Color.lerp(col, Colors.white, (shade - 0.5) * 0.4)!
            : Color.lerp(col, Colors.black, (0.5 - shade) * 0.15)!;
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(ang);
        canvas.scale(s);
        final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: tile, height: tile), const Radius.circular(5));
        fill.color = c.withValues(alpha: appear.clamp(0.0, 1.0));
        canvas.drawRRect(r, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-tile / 2 + 2.5, -tile / 2 + 2.5, tile - 5, tile * 0.42),
              const Radius.circular(4)),
          gloss,
        );
        edge.color = Color.lerp(c, Colors.black, 0.3)!.withValues(alpha: 0.4 * appear);
        canvas.drawRRect(r, edge);
        canvas.restore();
      }
    }
  }

  /// Points every [step] along the rounded rect, clockwise from the top
  /// centre: (position, tangent angle, 0..1 along the way).
  static List<(Offset, double, double)> _alongRRect(RRect r, double step) {
    final path = Path()..addRRect(r);
    final metric = path.computeMetrics().first;
    final len = metric.length;
    final n = (len / step).floor();
    final out = <(Offset, double, double)>[];
    // addRRect starts at the left end of the top edge; shift so we start at
    // the top centre.
    final startOffset = r.width / 2 - r.tlRadiusX;
    for (var i = 0; i < n; i++) {
      final d = (startOffset + i * len / n) % len;
      final t = metric.getTangentForOffset(d);
      if (t == null) continue;
      out.add((t.position, -t.angle, i / n));
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.progress != progress;
}
