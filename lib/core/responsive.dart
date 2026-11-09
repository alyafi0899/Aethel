import 'package:flutter/widgets.dart';

/// Breakpoints (viewport width) mirroring the original web design.
abstract final class Breakpoints {
  static const double desktop = 850; // sidebar becomes permanent
  static const double phone = 600;

  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= desktop;
  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width < phone;
}

/// Column helper based on the *available content width* (not the viewport).
int cols(double width, {int wide = 3, int mid = 2, int narrow = 1}) {
  if (width >= 880) return wide;
  if (width >= 520) return mid;
  return narrow;
}
