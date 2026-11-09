import 'package:flutter/material.dart';

import 'theme_config.dart';

/// Semantic status colours used by badges, icon boxes, avatars and notices.
enum Tone { green, amber, blue, red, gray, teal, violet, navy, pink }

typedef ToneColors = ({Color bg, Color fg});

/// All app colours as a [ThemeExtension]. Read them with `context.c`.
///
/// Built from a [BrandPalette] + brightness, so changing the palette or
/// switching to dark mode restyles every widget automatically.
@immutable
class ClinicColors extends ThemeExtension<ClinicColors> {
  const ClinicColors._({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderSoft,
    required this.text,
    required this.textSecondary,
    required this.muted,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.accent,
    required this.sidebar,
    required this.sidebarActive,
    required this.sidebarText,
    required this.sidebarMuted,
    required this.hero,
    required this.danger,
    required this.tones,
  });

  factory ClinicColors.from(BrandPalette p, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF16212F) : Colors.white;

    Color tint(Color c, double a) =>
        Color.alphaBlend(c.withValues(alpha: a), surface);

    ToneColors fixed(Color lightBg, Color lightFg) => dark
        ? (bg: tint(lightFg, .20), fg: lighten(lightFg))
        : (bg: lightBg, fg: lightFg);

    ToneColors derived(Color base) => dark
        ? (bg: tint(base, .20), fg: lighten(base))
        : (bg: tint(base, .10), fg: base);

    return ClinicColors._(
      isDark: dark,
      bg: dark ? const Color(0xFF0F1722) : const Color(0xFFF5F7FA),
      surface: surface,
      surfaceAlt: dark ? const Color(0xFF1B2839) : const Color(0xFFF8FAFB),
      border: dark ? const Color(0xFF263548) : const Color(0xFFE3E8EF),
      borderSoft: dark ? const Color(0xFF202D3E) : const Color(0xFFEDF0F3),
      text: dark ? const Color(0xFFE6EDF5) : const Color(0xFF182230),
      textSecondary: dark ? const Color(0xFFB3C0CE) : const Color(0xFF536171),
      muted: dark ? const Color(0xFF8393A5) : const Color(0xFF687586),
      primary: dark ? lighten(p.primary, .08) : p.primary,
      primaryDark: p.primaryDark,
      onPrimary: Colors.white,
      accent: p.accent,
      sidebar: p.sidebar,
      sidebarActive: Color.alphaBlend(
        Colors.white.withValues(alpha: .09),
        p.sidebar,
      ),
      sidebarText: const Color(0xFF94A5B6),
      sidebarMuted: const Color(0xFF61758A),
      hero: Color.lerp(p.sidebar, p.primary, .22)!,
      danger: const Color(0xFFC93F3F),
      tones: {
        Tone.green: fixed(const Color(0xFFE6F6EF), const Color(0xFF12865A)),
        Tone.amber: fixed(const Color(0xFFFFF3DF), const Color(0xFFA96B16)),
        Tone.red: fixed(const Color(0xFFFAE9E9), const Color(0xFFBC4141)),
        Tone.gray: fixed(const Color(0xFFEDF0F3), const Color(0xFF617080)),
        Tone.violet: fixed(const Color(0xFFEEE9FA), const Color(0xFF7156AC)),
        Tone.navy: fixed(const Color(0xFFE8EEF3), const Color(0xFF294E6D)),
        Tone.pink: fixed(const Color(0xFFF9E3EC), const Color(0xFFAA4F72)),
        Tone.blue: derived(p.primary),
        Tone.teal: derived(p.accent),
      },
    );
  }

  /// Lightens a colour (used for dark-mode foregrounds and the brand mark).
  static Color lighten(Color c, [double amount = .28]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 0.8)).toColor();
  }

  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderSoft;
  final Color text;
  final Color textSecondary;
  final Color muted;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color accent;
  final Color sidebar;
  final Color sidebarActive;
  final Color sidebarText;
  final Color sidebarMuted;
  final Color hero;
  final Color danger;
  final Map<Tone, ToneColors> tones;

  Color fg(Tone t) => tones[t]!.fg;
  Color soft(Tone t) => tones[t]!.bg;

  // Colours are rebuilt from the palette, so a plain swap is enough.
  @override
  ClinicColors copyWith() => this;

  @override
  ClinicColors lerp(ThemeExtension<ClinicColors>? other, double t) =>
      other is ClinicColors ? (t < .5 ? this : other) : this;
}
