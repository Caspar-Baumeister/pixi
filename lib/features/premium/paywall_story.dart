import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/links.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../models/templates.dart';
import '../../services/analytics.dart';
import '../../widgets/pixi_cat.dart';

/// The scrollable "sales story" under the plan cards: why keeping a pixel
/// per day works (four research findings, each with its own animation) and
/// what Pixi feels like after the paywall.
///
/// Returned as a list so the surrounding ListView builds each card lazily:
/// every card animates in the moment it scrolls into view.
///
/// Sources (checked; keep claims at this level of certainty):
///  * Fredrickson & Kahneman 1993, J. Personality and Social Psychology,
///    "Duration neglect in retrospective evaluations of affective episodes":
///    remembered episodes are judged by peak and end (peak-end rule).
///  * Lieberman et al. 2007, Psychological Science, "Putting feelings into
///    words": affect labeling lowers the amygdala response.
///  * Harkin et al. 2016, Psychological Bulletin: meta-analysis of 138
///    studies (N = 19,951), monitoring goal progress promotes goal
///    attainment; larger effects when progress is physically recorded.
///  * Lally et al. 2010, European Journal of Social Psychology: median 66
///    days until a new behaviour is automatic (range 18 to 254).
List<Widget> paywallStory(BuildContext context) => const [
      _StoryHeader(),
      _Reveal(section: 'memory', child: _MemoryCard()),
      _Reveal(section: 'naming', child: _NamingCard()),
      _Reveal(section: 'tracking', child: _TrackingCard()),
      _Reveal(section: 'patterns', child: _PatternCard()),
      SizedBox(height: 18),
      _Reveal(section: 'calm', child: _CalmCard()),
      SizedBox(height: 22),
      _Reveal(section: 'footer', child: _CatFooter()),
    ];

// Mood colours of the "mood" template, from heavy to radiant.
List<Color> get _mood => [for (final l in templateById('mood').levels) l.color];
// Sleep colours, from barely slept to deep sleep.
List<Color> get _sleep => [for (final l in templateById('sleep').levels) l.color];

// ---------------------------------------------------------------------------
// Scaffolding

class _StoryHeader extends StatelessWidget {
  const _StoryHeader();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          const Icon(Icons.keyboard_arrow_down_rounded, color: PixiColors.muted, size: 28),
          const SizedBox(height: 6),
          _Eyebrow(s.t('pw_story_eyebrow')),
          const SizedBox(height: 6),
          Text(s.t('pw_story_title'), textAlign: TextAlign.center, style: PixiText.title(size: 27)),
          const SizedBox(height: 8),
          Text(s.t('pw_story_sub'), textAlign: TextAlign.center, style: PixiText.body1(size: 14, color: PixiColors.muted)),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: PixiText.label(size: 11.5, color: BaseColors.plum).copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w800),
      );
}

/// Fades and lifts its child in the first time it is built.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.section, required this.child});
  final String section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Built lazily by the ListView, i.e. when it scrolls near the viewport:
    // good enough as a "scrolled this far" signal for the paywall funnel.
    Analytics.instance.trackOnce('pw_$section', 'paywall_section_viewed', {'section': section});
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

/// Drives an illustration from 0 to 1 once.
class _Play extends StatelessWidget {
  const _Play({required this.builder, this.ms = 1800, this.curve = Curves.easeInOutCubic});
  final Widget Function(BuildContext context, double t) builder;
  final int ms;
  final Curve curve;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: ms),
        curve: curve,
        builder: (context, v, _) => builder(context, v),
      );
}

/// Progress of one step inside a longer animation, 0..1.
double _seg(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

/// One chapter: eyebrow, big claim, illustration, what Pixi does about it,
/// and the source.
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.eyebrow,
    required this.headline,
    required this.art,
    required this.body,
    required this.source,
  });
  final String eyebrow;
  final String headline;
  final Widget art;
  final String body;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: PixiColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: PixiColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(eyebrow),
          const SizedBox(height: 6),
          Text(headline, style: PixiText.title(size: 22)),
          const SizedBox(height: 16),
          art,
          const SizedBox(height: 14),
          Text(body, style: PixiText.body1(size: 14, color: PixiColors.ink).copyWith(height: 1.45)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.menu_book_rounded, size: 12, color: PixiColors.muted),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(source, style: PixiText.label(size: 11).copyWith(fontStyle: FontStyle.italic, height: 1.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded pixel.
class _Px extends StatelessWidget {
  const _Px(this.color, {this.size = 18, this.scale = 1, this.ring = false});
  final Color color;
  final double size;
  final double scale;
  final bool ring;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size * 0.28),
                border: ring ? Border.all(color: PixiColors.ink, width: 1.6) : null,
              ),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// 1 · Memory keeps the peak and the end

class _MemoryCard extends StatelessWidget {
  const _MemoryCard();

  // Two weeks of mood (0 heavy .. 4 radiant). Peak on day 5, the end on day 14.
  static const _days = [2, 3, 2, 3, 0, 2, 3, 3, 2, 3, 3, 2, 3, 4];
  static const _peak = 4;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _StoryCard(
      eyebrow: s.t('pw_mem_eyebrow'),
      headline: s.t('pw_mem_title'),
      body: s.t('pw_mem_body'),
      source: s.t('pw_mem_src'),
      art: _Play(
        ms: 2600,
        curve: Curves.linear,
        builder: (context, t) => LayoutBuilder(builder: (context, c) {
          final size = math.min(20.0, (c.maxWidth - 13 * 4) / 14);
          Widget row(List<Widget> cells) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: cells,
              );
          final fill = _seg(t, 0, 0.45);
          final fade = Curves.easeInOut.transform(_seg(t, 0.5, 0.95));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('pw_mem_real'), style: PixiText.label(size: 11.5)),
              const SizedBox(height: 6),
              row([
                for (var i = 0; i < _days.length; i++)
                  _Px(
                    _mood[_days[i]],
                    size: size,
                    scale: Curves.easeOutBack.transform(_seg(fill, i / 14, (i + 1) / 14)),
                  ),
              ]),
              const SizedBox(height: 14),
              Text(s.t('pw_mem_recalled'), style: PixiText.label(size: 11.5)),
              const SizedBox(height: 6),
              row([
                for (var i = 0; i < _days.length; i++)
                  if (i == _peak || i == _days.length - 1)
                    _Px(_mood[_days[i]], size: size, scale: 1 + 0.12 * math.sin(fade * math.pi), ring: fade > 0.5)
                  else
                    _Px(
                      Color.lerp(_mood[_days[i]], PixiColors.emptyCell, fade)!,
                      size: size,
                      scale: 1 - 0.25 * fade,
                    ),
              ]),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Naming the feeling calms the alarm

class _NamingCard extends StatelessWidget {
  const _NamingCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _StoryCard(
      eyebrow: s.t('pw_name_eyebrow'),
      headline: s.t('pw_name_title'),
      body: s.t('pw_name_body'),
      source: s.t('pw_name_src'),
      art: _Play(
        ms: 3200,
        curve: Curves.linear,
        builder: (context, t) {
          final pop = Curves.elasticOut.transform(_seg(t, 0.32, 0.6));
          return SizedBox(
            height: 120,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _AlarmPainter(t))),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Opacity(
                    opacity: _seg(t, 0.32, 0.4),
                    child: Transform.scale(
                      scale: pop,
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _mood[1],
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(s.t('pw_name_word'), style: PixiText.label(size: 12, color: Colors.white).copyWith(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: -6,
                  bottom: -6,
                  child: PixiCat(size: 70, catId: 'meditation', animate: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A restless line that calms down once the feeling has a name.
class _AlarmPainter extends CustomPainter {
  _AlarmPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - 70; // room for the cat
    final mid = size.height * 0.62;
    final drawn = _seg(t, 0, 0.9);
    final path = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final x = i / steps;
      if (x > drawn) break;
      // Wild before the label (x < 0.35), then the amplitude drops away.
      final calm = Curves.easeOut.transform(((x - 0.35) / 0.5).clamp(0.0, 1.0));
      final amp = size.height * 0.3 * (1 - 0.85 * calm);
      final y = mid + amp * math.sin(x * 38) * (0.75 + 0.25 * math.sin(x * 11));
      if (i == 0) {
        path.moveTo(x * w, y);
      } else {
        path.lineTo(x * w, y);
      }
    }
    final paint = Paint()
      ..shader = LinearGradient(colors: [_mood[0], _mood[3], _mood[4]]).createShader(Offset.zero & Size(w, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    // The moment of naming: a soft dot on the line.
    final k = _seg(t, 0.32, 0.45);
    if (k > 0) {
      canvas.drawCircle(Offset(0.35 * w, mid), 5 * k, Paint()..color = PixiColors.ink);
    }
  }

  @override
  bool shouldRepaint(_AlarmPainter o) => o.t != t;
}

// ---------------------------------------------------------------------------
// 3 · Tracking: a month fills up

class _TrackingCard extends StatelessWidget {
  const _TrackingCard();

  // 30 days of mood, slowly getting lighter.
  static const _month = [
    1, 2, 0, 2, 1, 2, 3, 2, 1, 2, //
    3, 2, 2, 3, 1, 3, 3, 2, 3, 4, //
    3, 2, 3, 4, 3, 3, 4, 2, 4, 4,
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _StoryCard(
      eyebrow: s.t('pw_track_eyebrow'),
      headline: s.t('pw_track_title'),
      body: s.t('pw_track_body'),
      source: s.t('pw_track_src'),
      art: _Play(
        ms: 3000,
        curve: Curves.easeInOut,
        builder: (context, t) {
          final shown = (t * _month.length).floor().clamp(0, _month.length);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  const cols = 10;
                  final size = math.min(24.0, (c.maxWidth - (cols - 1) * 5) / cols);
                  return Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (var i = 0; i < _month.length; i++)
                        _Px(
                          i < shown ? _mood[_month[i]] : PixiColors.futureCell,
                          size: size,
                          scale: i == shown - 1 && t < 1 ? 1.15 : 1,
                          ring: i == shown - 1 && t < 1,
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${math.max(1, shown)}', style: PixiText.title(size: 34)),
                  Text(s.t('pw_track_day').replaceAll('{n}', '').trim(), style: PixiText.label(size: 11)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Patterns: sleep and mood move together

class _PatternCard extends StatelessWidget {
  const _PatternCard();

  // Ten days. Short nights (sleep 0/1) line up with heavy days (mood 0/1).
  static const _sleepDays = [3, 1, 3, 4, 0, 3, 2, 4, 1, 3];
  static const _moodDays = [3, 1, 3, 4, 0, 3, 2, 4, 0, 3];
  static const _links = [1, 4, 8];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _StoryCard(
      eyebrow: s.t('pw_pat_eyebrow'),
      headline: s.t('pw_pat_title'),
      body: s.t('pw_pat_body'),
      source: s.t('pw_pat_src'),
      art: _Play(
        ms: 2600,
        curve: Curves.linear,
        builder: (context, t) => LayoutBuilder(builder: (context, c) {
          const labelW = 64.0;
          final size = math.min(22.0, (c.maxWidth - labelW - 9 * 5) / 10);
          final gap = (c.maxWidth - labelW - size * 10) / 9;
          final fill = _seg(t, 0, 0.4);
          final link = Curves.easeOut.transform(_seg(t, 0.45, 0.85));
          Widget row(String label, List<int> days, List<Color> colors) => Row(
                children: [
                  SizedBox(width: labelW, child: Text(label, style: PixiText.label(size: 11.5))),
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    _Px(
                      colors[days[i]],
                      size: size,
                      scale: Curves.easeOutBack.transform(_seg(fill, i / 10, (i + 1) / 10)) *
                          (_links.contains(i) ? 1 + 0.12 * link : 1),
                    ),
                  ],
                ],
              );
          return SizedBox(
            height: size * 2 + 28,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LinkPainter(
                      progress: link,
                      xs: [for (final i in _links) labelW + i * (size + gap) + size / 2],
                      top: size,
                      bottom: size + 28,
                    ),
                  ),
                ),
                Column(
                  children: [
                    row(s.t('pw_pat_sleep'), _sleepDays, _sleep),
                    const SizedBox(height: 28),
                    row(s.t('pw_pat_mood'), _moodDays, _mood),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({required this.progress, required this.xs, required this.top, required this.bottom});
  final double progress;
  final List<double> xs;
  final double top;
  final double bottom;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final p = Paint()
      ..color = BaseColors.plum
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < xs.length; i++) {
      final k = _seg(progress, i * 0.2, i * 0.2 + 0.6);
      if (k == 0) continue;
      final y0 = top + 3;
      final y1 = y0 + (bottom - 3 - y0) * k;
      canvas.drawLine(Offset(xs[i], y0), Offset(xs[i], y1), p);
    }
  }

  @override
  bool shouldRepaint(_LinkPainter o) => o.progress != progress;
}

// ---------------------------------------------------------------------------
// After this screen

class _CalmCard extends StatelessWidget {
  const _CalmCard();

  static const _spots = [
    Alignment(-1, -0.75),
    Alignment(-0.92, 0.05),
    Alignment(-1, 0.8),
    Alignment(1, -0.65),
    Alignment(0.94, 0.12),
    Alignment(1, 0.85),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final gone = [
      s.t('pw_gone_ads'),
      s.t('pw_gone_account'),
      s.t('pw_gone_cloud'),
      s.t('pw_gone_feeds'),
      s.t('pw_gone_guilt'),
      s.t('pw_gone_popups'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BaseColors.plum.withValues(alpha: 0.16), PixiColors.card],
        ),
        border: Border.all(color: PixiColors.line),
      ),
      child: Column(
        children: [
          _Eyebrow(s.t('pw_calm_eyebrow')),
          const SizedBox(height: 6),
          Text(s.t('pw_calm_title'), textAlign: TextAlign.center, style: PixiText.title(size: 24)),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: _Play(
              ms: 1800,
              curve: Curves.easeOutCubic,
              builder: (context, p) => Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < gone.length; i++)
                    Align(
                      alignment: _spots[i],
                      child: Opacity(
                        opacity: (1 - 0.45 * p).clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: (i.isEven ? -0.08 : 0.07) * p,
                          child: _GoneChip(gone[i], struck: p),
                        ),
                      ),
                    ),
                  _MiniPhone(progress: p),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Promise(icon: Icons.block_rounded, text: s.t('pw_promise_ads')),
          _Promise(icon: Icons.lock_outline_rounded, text: s.t('pw_promise_data')),
          _Promise(icon: Icons.favorite_border_rounded, text: s.t('pw_promise_kind')),
        ],
      ),
    );
  }
}

class _GoneChip extends StatelessWidget {
  const _GoneChip(this.text, {required this.struck});
  final String text;
  final double struck;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: PixiColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PixiColors.line),
        ),
        child: CustomPaint(
          foregroundPainter: _StrikePainter(struck, BaseColors.berry),
          child: Text(text, style: PixiText.label(size: 11.5).copyWith(fontWeight: FontWeight.w800)),
        ),
      );
}

class _StrikePainter extends CustomPainter {
  _StrikePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = ((t - 0.3) / 0.5).clamp(0.0, 1.0);
    if (k == 0) return;
    final y = size.height / 2 + 1;
    canvas.drawLine(
      Offset(-2, y),
      Offset(-2 + (size.width + 4) * k, y),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter o) => o.t != t;
}

/// A tiny iPhone whose year grid fills while the noise around it fades.
class _MiniPhone extends StatelessWidget {
  const _MiniPhone({required this.progress});
  final double progress;

  static const _cols = 7;
  static const _rows = 9;

  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(7);
    final cells = [for (var i = 0; i < _cols * _rows; i++) 1 + rnd.nextInt(4)];
    final shown = (progress * cells.length).round();
    return Container(
      width: 128,
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: PixiColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PixiColors.ink.withValues(alpha: 0.85), width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 8,
            decoration: BoxDecoration(color: PixiColors.ink.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 6),
          const PixiCat(size: 46, catId: 'happy', animate: false),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final size = math.min((c.maxWidth - (_cols - 1) * 3) / _cols, (c.maxHeight - (_rows - 1) * 3) / _rows);
              return Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (var i = 0; i < cells.length; i++)
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: i < shown ? _mood[cells[i]] : PixiColors.futureCell,
                        borderRadius: BorderRadius.circular(size * 0.28),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: BaseColors.plum),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: PixiText.body1(size: 13.5, color: PixiColors.ink).copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Footer: a row of cats and the maker's note

class _CatFooter extends StatelessWidget {
  const _CatFooter();

  static const _cats = [('sleep', 54.0), ('reading', 62.0), ('happy', 76.0), ('gym', 62.0), ('water', 54.0)];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (id, h) in _cats) PixiCat(size: h, catId: id, animate: false),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          s.t('pw_footer_note'),
          textAlign: TextAlign.center,
          style: PixiText.label(size: 12.5).copyWith(fontStyle: FontStyle.italic, height: 1.45),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {
            Analytics.instance.track('x_profile_tapped', {'source': 'paywall'});
            launchUrl(Uri.parse(Links.x), mode: LaunchMode.externalApplication);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            s.t('pw_footer_hi').replaceAll('{handle}', '@casparbuilds'),
            style: PixiText.label(size: 12, color: BaseColors.plum).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
