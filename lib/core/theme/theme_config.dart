import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  THEME SETTINGS  —  the one place to restyle the whole app.
//
//  1. Change the defaults in [kInitialThemeConfig] at the bottom of this file.
//  2. Add / edit brand colours in [BrandPalettes].
//  3. Or change them live at runtime: Settings > Appearance (it calls
//     ThemeController, so the same knobs are available from code).
// ═══════════════════════════════════════════════════════════════════════════

/// A brand colour set. Everything else (soft tints, status tones, dark mode
/// variants) is derived from these four colours.
class BrandPalette {
  const BrandPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.sidebar,
  });

  final String id;
  final String name;

  /// Buttons, active tabs, links, "blue" status tone.
  final Color primary;

  /// Pressed / hover state of [primary].
  final Color primaryDark;

  /// Secondary highlight (the "teal" tone, brand mark).
  final Color accent;

  /// Dark navigation sidebar background.
  final Color sidebar;
}

abstract final class BrandPalettes {
  static const clinicBlue = BrandPalette(
    id: 'clinic_blue',
    name: 'Clinic Blue',
    primary: Color(0xFF1769AA),
    primaryDark: Color(0xFF125486),
    accent: Color(0xFF17A89B),
    sidebar: Color(0xFF101D2D),
  );

  static const emerald = BrandPalette(
    id: 'emerald',
    name: 'Emerald',
    primary: Color(0xFF0F8A5F),
    primaryDark: Color(0xFF0B6B49),
    accent: Color(0xFF2E8BC0),
    sidebar: Color(0xFF0E211B),
  );

  static const violet = BrandPalette(
    id: 'violet',
    name: 'Violet',
    primary: Color(0xFF6D4FC2),
    primaryDark: Color(0xFF553BA0),
    accent: Color(0xFF17A89B),
    sidebar: Color(0xFF1A1630),
  );

  static const rose = BrandPalette(
    id: 'rose',
    name: 'Rose',
    primary: Color(0xFFC0355A),
    primaryDark: Color(0xFF9B2848),
    accent: Color(0xFFE9A23B),
    sidebar: Color(0xFF2A1520),
  );

  static const slate = BrandPalette(
    id: 'slate',
    name: 'Slate',
    primary: Color(0xFF334155),
    primaryDark: Color(0xFF1E293B),
    accent: Color(0xFF0EA5E9),
    sidebar: Color(0xFF0B1220),
  );

  /// Shown in the Settings > Appearance picker. Add your own here.
  static const all = <BrandPalette>[clinicBlue, emerald, violet, rose, slate];

  static BrandPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => clinicBlue);
}

/// Spacing / control-size preset.
enum UiDensity {
  compact('Compact', 0.85),
  comfortable('Comfortable', 1.0),
  spacious('Spacious', 1.2);

  const UiDensity(this.label, this.factor);
  final String label;
  final double factor;
}

/// Immutable bundle of every theme knob.
@immutable
class AppThemeConfig {
  const AppThemeConfig({
    this.palette = BrandPalettes.clinicBlue,
    this.mode = ThemeMode.light,
    this.radius = 7,
    this.density = UiDensity.comfortable,
    this.fontFamily = 'Inter',
    this.useGoogleFonts = true,
    this.fontScale = 1.0,
  });

  final BrandPalette palette;

  /// light / dark / system
  final ThemeMode mode;

  /// Base corner radius for cards (buttons & inputs derive from it).
  final double radius;

  final UiDensity density;

  /// Any Google Fonts family name when [useGoogleFonts] is true
  /// (e.g. 'Inter', 'Poppins', 'Manrope'); otherwise a bundled font family.
  final String fontFamily;
  final bool useGoogleFonts;

  /// Multiplies every font size. 1.0 = default, 0.9 = closer to the dense
  /// web mock-up, 1.15 = larger / more accessible.
  final double fontScale;

  AppThemeConfig copyWith({
    BrandPalette? palette,
    ThemeMode? mode,
    double? radius,
    UiDensity? density,
    String? fontFamily,
    bool? useGoogleFonts,
    double? fontScale,
  }) {
    return AppThemeConfig(
      palette: palette ?? this.palette,
      mode: mode ?? this.mode,
      radius: radius ?? this.radius,
      density: density ?? this.density,
      fontFamily: fontFamily ?? this.fontFamily,
      useGoogleFonts: useGoogleFonts ?? this.useGoogleFonts,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

/// >>> Edit the app's starting look here. <<<
const kInitialThemeConfig = AppThemeConfig(
  palette: BrandPalettes.clinicBlue,
  mode: ThemeMode.light,
  radius: 7,
  density: UiDensity.comfortable,
  fontFamily: 'Inter',
  useGoogleFonts: true,
  fontScale: 1.0,
);
