import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'clinic_colors.dart';
import 'clinic_metrics.dart';
import 'theme_config.dart';

/// Turns an [AppThemeConfig] into a Flutter [ThemeData].
abstract final class AppTheme {
  static ThemeData build(AppThemeConfig cfg, Brightness brightness) {
    final colors = ClinicColors.from(cfg.palette, brightness);
    final metrics = ClinicMetrics(
      radius: cfg.radius,
      density: cfg.density.factor,
    );
    final textTheme = _textTheme(cfg, colors);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: cfg.palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          surface: colors.surface,
          onSurface: colors.text,
          outline: colors.border,
          error: colors.fg(Tone.red),
        );

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(metrics.radiusSm),
      borderSide: BorderSide(color: color),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.surface,
      dividerColor: colors.border,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [colors, metrics],
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11 * metrics.control,
        ),
        hintStyle: textTheme.bodySmall!.copyWith(color: colors.muted),
        border: border(colors.border),
        enabledBorder: border(colors.border),
        focusedBorder: border(colors.primary),
        errorBorder: border(colors.fg(Tone.red)),
        focusedErrorBorder: border(colors.fg(Tone.red)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? colors.primary : null,
        ),
        side: BorderSide(color: colors.border, width: 1.4),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(colors.border),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.surface),
    );
  }

  static TextTheme _textTheme(AppThemeConfig cfg, ClinicColors c) {
    final s = cfg.fontScale;
    TextStyle ts(double size, FontWeight w, {double? ls, double? h}) =>
        TextStyle(
          fontSize: size * s,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: c.text,
        );

    final base = TextTheme(
      headlineMedium: ts(24, FontWeight.w700, ls: -.5, h: 1.2),
      titleMedium: ts(14.5, FontWeight.w700, h: 1.3),
      titleSmall: ts(13, FontWeight.w700, h: 1.3),
      bodyLarge: ts(14, FontWeight.w400, h: 1.4),
      bodyMedium: ts(12, FontWeight.w400, h: 1.35),
      bodySmall: ts(10.5, FontWeight.w400, h: 1.3),
      labelMedium: ts(12, FontWeight.w600),
      labelSmall: ts(9.5, FontWeight.w700, ls: .9),
    );

    return cfg.useGoogleFonts
        ? GoogleFonts.getTextTheme(cfg.fontFamily, base)
        : base.apply(fontFamily: cfg.fontFamily);
  }
}
