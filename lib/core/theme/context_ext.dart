import 'package:flutter/material.dart';

import 'clinic_colors.dart';
import 'clinic_metrics.dart';

/// Shorthand access to theme tokens:  `context.c.primary`, `context.sH1` ...
extension ClinicThemeContext on BuildContext {
  ClinicColors get c => Theme.of(this).extension<ClinicColors>()!;
  ClinicMetrics get m => Theme.of(this).extension<ClinicMetrics>()!;
  TextTheme get tt => Theme.of(this).textTheme;

  /// Page title.
  TextStyle get sH1 => tt.headlineMedium!;

  /// Card title.
  TextStyle get sH2 => tt.titleMedium!;

  /// Section title.
  TextStyle get sH3 => tt.titleSmall!;

  /// Regular secondary-colour text.
  TextStyle get sBody => tt.bodyMedium!.copyWith(color: c.textSecondary);

  /// Emphasised primary-colour text.
  TextStyle get sStrong =>
      tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: c.text);

  /// Small muted text (captions, sub-lines).
  TextStyle get sSmall => tt.bodySmall!.copyWith(color: c.muted);

  /// Uppercase micro label (table headers, eyebrows).
  TextStyle get sLabel => tt.labelSmall!.copyWith(color: c.muted);
}
