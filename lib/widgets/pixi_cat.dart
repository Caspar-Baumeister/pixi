import 'dart:async';

import 'package:flutter/material.dart';

/// The sketched cat, animated as a hand-drawn "boil" from 5 frames.
///
/// All maps currently share the same frames; `catId` is kept so each map
/// can get its own cat later (assets/cats/<catId>_1..5.png).
class PixiCat extends StatefulWidget {
  const PixiCat({
    super.key,
    this.size = 160,
    this.catId = 'pixi',
    this.animate = true,
    this.fps = 5,
    this.mirror = false,
  });

  final double size;
  final String catId;
  final bool animate;
  final double fps;
  final bool mirror;

  static const int frameCount = 5;

  /// Frame order for a lively but calm loop.
  static const List<int> sequence = [1, 2, 3, 4, 5, 4, 3, 2, 1, 3, 5, 2];

  static String asset(String catId, int frame) {
    // Only "pixi" frames exist in v1; other ids fall back to pixi.
    final id = catId == 'pixi' ? 'cat' : catId;
    return 'assets/cats/${id}_$frame.png';
  }

  static Future<void> precache(BuildContext context) async {
    for (var i = 1; i <= frameCount; i++) {
      await precacheImage(AssetImage(asset('pixi', i)), context);
    }
  }

  @override
  State<PixiCat> createState() => _PixiCatState();
}

class _PixiCatState extends State<PixiCat> {
  Timer? _timer;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant PixiCat old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate || old.fps != widget.fps) _start();
  }

  void _start() {
    _timer?.cancel();
    if (!widget.animate) return;
    final ms = (1000 / widget.fps).round();
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!mounted) return;
      setState(() => _idx = (_idx + 1) % PixiCat.sequence.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = PixiCat.sequence[_idx];
    Widget img = Image.asset(
      PixiCat.asset(widget.catId, frame),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (widget.mirror) {
      img = Transform.flip(flipX: true, child: img);
    }
    return SizedBox(width: widget.size, height: widget.size, child: img);
  }
}

/// Cat with a soft coloured glow behind it (used in onboarding / check-in).
class GlowingCat extends StatelessWidget {
  const GlowingCat({
    super.key,
    required this.color,
    this.size = 180,
    this.glowOpacity = 0.28,
    this.animate = true,
    this.catId = 'pixi',
  });

  final Color color;
  final double size;
  final double glowOpacity;
  final bool animate;
  final String catId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.5,
            height: size * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: glowOpacity),
                  color.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.75],
              ),
            ),
          ),
          PixiCat(size: size, animate: animate, catId: catId),
        ],
      ),
    );
  }
}
