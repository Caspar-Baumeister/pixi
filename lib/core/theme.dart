import 'package:flutter/material.dart';

/// Pixi design tokens – paper-like light UI, one accent colour per map.
class PixiColors {
  PixiColors._();

  static const Color paper = Color(0xFFFAF9F6);
  static const Color paperDark = Color(0xFFF1EFEA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFECEBE7);
  static const Color ink = Color(0xFF1B1B1F);
  static const Color inkSoft = Color(0xFF5A5A62);
  static const Color muted = Color(0xFF8A8A90);
  static const Color faint = Color(0xFFB9B9BE);
  static const Color emptyCell = Color(0xFFEBEAE6);
  static const Color futureCell = Color(0xFFF3F2EE);
  static const Color danger = Color(0xFFD9534F);
}

class PixiText {
  PixiText._();

  static const String display = 'Fraunces';
  static const String body = 'Manrope';

  static TextStyle title({double size = 28, Color color = PixiColors.ink}) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        height: 1.12,
        letterSpacing: -0.3,
        color: color,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
      );

  static TextStyle body1({double size = 16, Color color = PixiColors.inkSoft}) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        height: 1.4,
        color: color,
        fontWeight: FontWeight.w500,
        fontVariations: const [FontVariation('wght', 500)],
      );

  static TextStyle label({double size = 13, Color color = PixiColors.muted}) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        height: 1.3,
        color: color,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
      );

  static TextStyle button({Color color = Colors.white}) => TextStyle(
        fontFamily: body,
        fontSize: 16,
        color: color,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
      );
}

ThemeData buildPixiTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: PixiColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PixiColors.ink,
      brightness: Brightness.light,
      surface: PixiColors.paper,
    ),
    fontFamily: PixiText.body,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: PixiColors.paper,
      foregroundColor: PixiColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: PixiColors.ink,
      displayColor: PixiColors.ink,
      fontFamily: PixiText.body,
    ),
    dividerColor: PixiColors.line,
    splashFactory: InkSparkle.splashFactory,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PixiColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: PixiColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? PixiColors.ink
            : PixiColors.faint,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: PixiColors.ink,
      thumbColor: PixiColors.ink,
      inactiveTrackColor: PixiColors.line,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PixiColors.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PixiColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PixiColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PixiColors.ink, width: 1.4),
      ),
    ),
  );
}

/// Helpers for colours.
extension PixiColorX on Color {
  Color withOpacityF(double o) => withValues(alpha: o);

  /// Mix with another colour, t in 0..1.
  Color mix(Color other, double t) => Color.lerp(this, other, t)!;

  bool get isDark => computeLuminance() < 0.35;
}

/// Store colours as ARGB int in JSON.
int colorToInt(Color c) => c.toARGB32();
Color colorFromInt(int v) => Color(v);
