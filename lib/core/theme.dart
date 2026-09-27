import 'package:flutter/material.dart';

/// Color palette for Kids Learning Universe.
class AppColors {
  AppColors._();

  // Night-sky colors used on the universe map.
  static const spaceTop = Color(0xFF120B3A);
  static const spaceMid = Color(0xFF2A1A6E);
  static const spaceBottom = Color(0xFF53308F);
  static const nebulaPink = Color(0xFFFF6FB5);
  static const nebulaBlue = Color(0xFF4FC3FF);

  static const ink = Color(0xFF2D2A4A);
  static const inkSoft = Color(0xFF6E6A93);
  static const cream = Color(0xFFFFF8EE);
  static const white = Colors.white;

  static const star = Color(0xFFFFC93C);
  static const starDeep = Color(0xFFF2A007);
  static const success = Color(0xFF3CCB7F);
  static const successDeep = Color(0xFF22A462);
  static const oops = Color(0xFFFF7A7A);
  static const locked = Color(0xFFB9B4D6);

  // Subject colors.
  static const reading = Color(0xFFFF7A59);
  static const math = Color(0xFF3FA9F5);
  static const puzzles = Color(0xFF34C77B);
  static const art = Color(0xFFFF5FA2);
  static const stories = Color(0xFF8E6CF1);
  static const adventure = Color(0xFFFFB321);

  /// Bright colors for choices, confetti and drawing.
  static const playful = <Color>[
    Color(0xFFFF5A5F),
    Color(0xFFFF9F1C),
    Color(0xFFFFD23F),
    Color(0xFF3CCB7F),
    Color(0xFF3FA9F5),
    Color(0xFF8E6CF1),
    Color(0xFFFF5FA2),
    Color(0xFF2EC4B6),
  ];
}

extension ColorTools on Color {
  /// A darker shade, used for the "3D" bottom edge of buttons.
  Color darken([double amount = 0.18]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// A lighter tint, used for soft backgrounds.
  Color lighten([double amount = 0.18]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// A very pale version of the color for page backgrounds.
  Color get pastel => Color.lerp(this, Colors.white, 0.86)!;
}

class AppFonts {
  AppFonts._();
  static const display = 'Fredoka';

  /// Learner-friendly font for letters and words children read.
  static const reading = 'Andika';
  static const emoji = 'NotoColorEmoji';
  static const fallback = <String>[emoji];
}

/// Shorthand text styles.
class KidText {
  KidText._();

  static TextStyle display(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.15,
      );

  static TextStyle body(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.3,
      );

  /// Letters, words and sentences a child is learning to read.
  static TextStyle reading(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: AppFonts.reading,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.25,
      );

  static TextStyle emoji(double size) => TextStyle(
        fontFamily: AppFonts.emoji,
        fontSize: size,
        height: 1.0,
      );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.stories,
    brightness: Brightness.light,
  ).copyWith(primary: AppColors.stories, secondary: AppColors.adventure, surface: AppColors.cream);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.display,
    fontFamilyFallback: AppFonts.fallback,
    scaffoldBackgroundColor: AppColors.cream,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme().apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2DDF5), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2DDF5), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.stories, width: 3),
      ),
    ),
  );
}
