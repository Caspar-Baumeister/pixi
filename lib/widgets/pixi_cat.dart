import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pix_map.dart';

/// A looping cat animation made of a few hand-drawn keyframes.
///
/// Frames live in `assets/cats/<id>/01.png …` (square, transparent).
/// [seq] lists which frame (1-based) to show, [ms] how long each step lasts –
/// like classic animation with holds, so a handful of clean drawings is
/// enough.
class CatAnim {
  const CatAnim(this.id, this.frames, this.seq, this.ms)
      : file = null,
        still = null;

  /// A single animated file (animated WebP/GIF) that Flutter loops itself.
  /// [still] is one hand-picked, well-centred frame used whenever the cat must
  /// hold still – above all for shared / exported images.
  const CatAnim.animated(this.id, this.file, {this.still})
      : frames = 0,
        seq = const [1],
        ms = const [1000];

  final String? file;

  /// Poster frame for exports; falls back to the first frame.
  final String? still;

  final String id;
  final int frames;
  final List<int> seq;
  final List<int> ms;

  String frame(int n) => 'assets/cats/$id/${n.toString().padLeft(2, '0')}.png';
}

class CatAnims {
  CatAnims._();

  /// Default cat: sits, blinks now and then.
  /// Sit → stretch → sit: smooth 12 fps loop from the generated video.
  static const idle = CatAnim.animated('stretch', 'assets/cats/stretch.webp',
      still: 'assets/cats/stretch_still.png');

  /// Calm cat that fits any topic – the default for custom maps.
  static const neutral = CatAnim.animated('neutral', 'assets/cats/neutral_still.png',
      still: 'assets/cats/neutral_still.png');
  static const wave = CatAnim('wave', 4, [1, 2, 3, 4, 3, 4, 3, 2], [1400, 140, 170, 170, 170, 170, 170, 140]);
  static const curious = CatAnim('curious', 3, [1, 2, 1, 3], [1500, 1000, 600, 1000]);
  static const sad = CatAnim.animated('sad', 'assets/cats/sad.webp',
      still: 'assets/cats/sad_still.png');
  static const happy = CatAnim('happy', 5, [1, 2, 3, 4, 3, 5, 1], [1200, 110, 80, 170, 80, 110, 300]);
  static const gym = CatAnim.animated('gym', 'assets/cats/gym.webp',
      still: 'assets/cats/gym_still.png');
  static const bell = CatAnim('bell', 2, [1, 2, 1, 2], [1500, 260, 140, 260]);
  static const sleep = CatAnim.animated('sleep', 'assets/cats/sleep.webp',
      still: 'assets/cats/sleep_still.png');

  static final Map<String, CatAnim> all = {
    for (final a in [idle, neutral, wave, curious, sad, happy, gym, bell, sleep]) a.id: a,
  };

  /// Cats the user can pick for a map, in the order shown in the editor.
  static const pickable = [neutral, idle, happy, wave, curious, gym, sleep, sad, bell];

  /// Label key for the picker (resolved via `S.t`).
  static String labelKey(String id) => 'cat_$id';

  static CatAnim byId(String id) {
    if (id == 'pixi' || id.isEmpty || id == 'stretch') return idle;
    return all[id] ?? idle;
  }

  /// The cat that belongs to a map (gym cat for training, sleepy cat for
  /// sleep …). Works for maps created before catIds existed, too.
  static CatAnim forMap(PixMap? m) {
    if (m == null) return idle;
    if (m.catId != 'pixi' && all.containsKey(m.catId)) return all[m.catId]!;
    const byTemplate = {'training': 'gym', 'sleep': 'sleep', 'dreams': 'sleep', 'cry': 'sad'};
    return all[byTemplate[m.templateId]] ?? idle;
  }
}

/// The sketched cat. [size] is width and height (frames are square).
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
      if (a.file != null) {
        await precacheImage(AssetImage(a.file!), context);
        if (a.still != null) await precacheImage(AssetImage(a.still!), context);
        continue;
      }
      for (var i = 1; i <= a.frames; i++) {
        await precacheImage(AssetImage(a.frame(i)), context);
      }
    }
  }

  @override
  State<PixiCat> createState() => _PixiCatState();
}

class _PixiCatState extends State<PixiCat> {
  Timer? _timer;
  int _step = 0;

  CatAnim get _anim => widget.anim ?? CatAnims.byId(widget.catId);

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant PixiCat old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate || old.catId != widget.catId || old.anim?.id != widget.anim?.id) {
      _step = 0;
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.animate) return;
    final a = _anim;
    if (a.file != null) return; // the image widget animates on its own
    _timer = Timer(Duration(milliseconds: a.ms[_step % a.ms.length]), () {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % a.seq.length);
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
    final a = _anim;
    final asset = !widget.animate && a.still != null
        ? a.still!
        : (a.file ?? a.frame(a.seq[_step % a.seq.length]));
    Widget img = Image.asset(
      asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (widget.mirror) img = Transform.flip(flipX: true, child: img);
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
      width: size * 1.5,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.4,
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
