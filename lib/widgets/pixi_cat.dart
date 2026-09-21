import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pix_map.dart';

/// One looping sprite animation of the sketched cat.
class CatAnim {
  const CatAnim(this.id, this.frames, {this.fps = 10, this.holdMs = 1600});

  /// Folder under assets/cats/.
  final String id;
  final int frames;
  final double fps;

  /// Pause on the first frame before the loop plays again (calm idle).
  final int holdMs;

  String frame(int i) => 'assets/cats/$id/${(i + 1).toString().padLeft(2, '0')}.png';
}

/// All animations that ship with the app. Map-specific cats fall back to
/// [stretch] until their sprite sheet exists.
class CatAnims {
  CatAnims._();
  static const stretch = CatAnim('stretch', 25, fps: 11, holdMs: 1800);
  static const gym = CatAnim('gym', 20, fps: 9, holdMs: 500);
  static const sad = CatAnim('sad', 20, fps: 7, holdMs: 900);
  static const sleep = CatAnim('sleep', 20, fps: 5, holdMs: 200);

  static final Map<String, CatAnim> all = {
    'stretch': stretch,
    'gym': gym,
    'sad': sad,
    'sleep': sleep,
  };

  /// Registers an animation (used for the optional extra sheets).
  static void register(CatAnim a) => all[a.id] = a;

  static CatAnim byId(String id) {
    if (id == 'pixi' || id.isEmpty) return stretch;
    return all[id] ?? stretch;
  }

  /// The cat that belongs to a map (gym cat for training, sleepy cat for
  /// sleep …). Works for maps created before catIds existed, too.
  static CatAnim forMap(PixMap? m) {
    if (m == null) return stretch;
    if (m.catId != 'pixi' && all.containsKey(m.catId)) return all[m.catId]!;
    const byTemplate = {'training': 'gym', 'sleep': 'sleep', 'dreams': 'sleep', 'cry': 'sad'};
    final id = byTemplate[m.templateId];
    return id != null && all.containsKey(id) ? all[id]! : stretch;
  }
}

/// The sketched cat, playing a looping sprite animation.
///
/// [size] is the height; the frames are 4:3, so the widget is `size * 4/3`
/// wide.
class PixiCat extends StatefulWidget {
  const PixiCat({
    super.key,
    this.size = 160,
    this.catId = 'pixi',
    this.anim,
    this.animate = true,
    this.mirror = false,
  });

  final double size;
  final String catId;
  final CatAnim? anim;
  final bool animate;
  final bool mirror;

  static Future<void> precache(BuildContext context) async {
    for (final a in CatAnims.all.values) {
      for (var i = 0; i < a.frames; i++) {
        await precacheImage(AssetImage(a.frame(i)), context);
      }
    }
  }

  @override
  State<PixiCat> createState() => _PixiCatState();
}

class _PixiCatState extends State<PixiCat> {
  Timer? _timer;
  int _frame = 0;

  CatAnim get _anim => widget.anim ?? CatAnims.byId(widget.catId);

  @override
  void initState() {
    super.initState();
    _schedule(initial: true);
  }

  @override
  void didUpdateWidget(covariant PixiCat old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate || old.catId != widget.catId || old.anim?.id != widget.anim?.id) {
      _frame = 0;
      _schedule(initial: true);
    }
  }

  void _schedule({bool initial = false}) {
    _timer?.cancel();
    if (!widget.animate) return;
    final a = _anim;
    final frameMs = (1000 / a.fps).round();
    final wait = _frame == 0 ? (initial ? 600 : a.holdMs) : frameMs;
    _timer = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % a.frames);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size * 4 / 3;
    Widget img = Image.asset(
      _anim.frame(_frame),
      width: w,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (widget.mirror) img = Transform.flip(flipX: true, child: img);
    return SizedBox(width: w, height: widget.size, child: img);
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
    this.anim,
  });

  final Color color;
  final double size;
  final double glowOpacity;
  final bool animate;
  final String catId;
  final CatAnim? anim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.5,
            height: size * 1.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: glowOpacity), color.withValues(alpha: 0)],
                stops: const [0.0, 0.75],
              ),
            ),
          ),
          PixiCat(size: size, animate: animate, catId: catId, anim: anim),
        ],
      ),
    );
  }
}
