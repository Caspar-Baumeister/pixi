import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../models/pix_map.dart';
import 'pixel_grid.dart';

/// Full-width pill button (Amy-style bottom CTA).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = PixiColors.ink,
    this.textColor = Colors.white,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color,
            foregroundColor: textColor,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: textColor),
                )
              : Text(label, style: PixiText.button(color: textColor)),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: PixiColors.inkSoft,
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: PixiText.button(color: PixiColors.inkSoft)),
      ),
    );
  }
}

/// Round icon button on paper (back arrow etc.).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, this.onTap, this.size = 44});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PixiColors.paperDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: onTap == null ? PixiColors.faint : PixiColors.ink),
        ),
      ),
    );
  }
}

/// White rounded card with the paper hairline.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.glowColor,
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? glowColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: PixiColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: PixiColors.line),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(color: glowColor!.withValues(alpha: 0.28), blurRadius: 40, spreadRadius: 2),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// The level chooser: a row of coloured circles with labels underneath.
class LevelPicker extends StatelessWidget {
  const LevelPicker({
    super.key,
    required this.map,
    required this.onPick,
    this.selected,
    this.size = 52,
  });

  final PixMap map;
  final int? selected;
  final void Function(int level) onPick;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final n = map.levels.length;
    final dotSize = n > 4 ? size * 0.9 : size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < n; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onPick(i);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    width: selected == i ? dotSize * 1.18 : dotSize,
                    height: selected == i ? dotSize * 1.18 : dotSize,
                    decoration: BoxDecoration(
                      color: map.levels[i].color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == i ? PixiColors.ink : Colors.white,
                        width: selected == i ? 2.5 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: map.baseColor.withValues(alpha: selected == i ? 0.5 : 0.22),
                          blurRadius: selected == i ? 22 : 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.r(map.levels[i].label),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: PixiText.label(
                      size: 11.5,
                      color: selected == i ? PixiColors.ink : PixiColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Portrait map card: title, glowing grid, legend – used in the onboarding
/// carousel and the maps overview.
class MapCard extends StatelessWidget {
  const MapCard({
    super.key,
    required this.map,
    required this.entries,
    required this.year,
    this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
    this.showLegend = true,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 14),
  });

  final PixMap map;
  final Map<String, int> entries;
  final int year;
  final String? title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool showLegend;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: PixiColors.card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? PixiColors.ink : PixiColors.line,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: map.baseColor.withValues(alpha: selected ? 0.42 : 0.22),
              blurRadius: selected ? 56 : 32,
              spreadRadius: selected ? 4 : 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title ?? s.r(map.title), style: PixiText.title(size: 20)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: PixiText.label(size: 12)),
            ],
            const SizedBox(height: 12),
            PixelGrid(map: map, entries: entries, year: year, showLabels: true),
            if (showLegend) ...[
              const SizedBox(height: 12),
              MapLegend(map: map, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin progress bar for onboarding / check-in.
class ThinProgress extends StatelessWidget {
  const ThinProgress({super.key, required this.value, this.color = PixiColors.ink});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: PixiColors.line),
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                widthFactor: value.clamp(0.02, 1.0),
                heightFactor: 1,
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
