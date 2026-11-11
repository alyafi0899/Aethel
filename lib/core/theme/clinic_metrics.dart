import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Shape / spacing tokens as a [ThemeExtension]. Read them with `context.m`.
@immutable
class ClinicMetrics extends ThemeExtension<ClinicMetrics> {
  const ClinicMetrics({required this.radius, required this.density});

  /// Base card radius.
  final double radius;

  /// 0.85 compact · 1.0 comfortable · 1.2 spacious.
  final double density;

  double get radiusSm => (radius - 2).clamp(2.0, 100.0);
  double get radiusLg => radius + 3;

  /// Button / input height multiplier (changes half as fast as [density]).
  double get control => 1 + (density - 1) * 0.5;

  double get rowHeight => 58 * density;

  @override
  ClinicMetrics copyWith({double? radius, double? density}) => ClinicMetrics(
        radius: radius ?? this.radius,
        density: density ?? this.density,
      );

  @override
  ClinicMetrics lerp(ThemeExtension<ClinicMetrics>? other, double t) {
    if (other is! ClinicMetrics) return this;
    return ClinicMetrics(
      radius: lerpDouble(radius, other.radius, t)!,
      density: lerpDouble(density, other.density, t)!,
    );
  }
}
