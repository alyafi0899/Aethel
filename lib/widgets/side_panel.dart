import 'package:flutter/material.dart';

/// Opens [builder] as a right-aligned drawer panel (like the web design's
/// appointment / triage drawers). The panel is a dialog route, so it can be
/// dismissed with the scrim, the back button or Navigator.pop.
Future<T?> showSidePanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double width = 510,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close panel',
    barrierColor: const Color(0x700E1D2A),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) {
      final w = MediaQuery.sizeOf(ctx).width;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Theme.of(ctx).colorScheme.surface,
          elevation: 12,
          child: SizedBox(
            width: w < width ? w : width,
            height: double.infinity,
            child: builder(ctx),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
