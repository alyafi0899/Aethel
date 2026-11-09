import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/context_ext.dart';

enum BtnKind { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.kind = BtnKind.secondary,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    late final Color bg;
    late final Color fg;
    late final Color border;
    switch (kind) {
      case BtnKind.primary:
        bg = c.primary;
        fg = c.onPrimary;
        border = c.primary;
      case BtnKind.secondary:
        bg = c.surface;
        fg = c.textSecondary;
        border = c.border;
      case BtnKind.ghost:
        bg = Colors.transparent;
        fg = c.muted;
        border = Colors.transparent;
      case BtnKind.danger:
        bg = c.danger;
        fg = Colors.white;
        border = c.danger;
    }

    final h = (compact ? 32.0 : 36.0) * context.m.control;
    final radius = BorderRadius.circular(context.m.radiusSm);

    return Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          hoverColor: kind == BtnKind.primary ? c.primaryDark : null,
          child: Container(
            height: h,
            padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: context.tt.labelMedium!.copyWith(color: fg),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 7),
                  Icon(trailingIcon, size: 14, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square bordered icon button (header actions, close buttons ...).
class AppIconButton extends StatelessWidget {
  const AppIconButton(
    this.icon, {
    super.key,
    this.onPressed,
    this.dot = false,
    this.size = 34,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool dot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.m.radiusSm);
    return Material(
      color: context.c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.c.border),
      ),
      child: InkWell(
        onTap: onPressed ?? () {},
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: context.c.muted),
              if (dot)
                Positioned(
                  right: 7,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE15050),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.c.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience for the close "X" of drawers / dialogs.
class CloseIconButton extends StatelessWidget {
  const CloseIconButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      AppIconButton(AppIcons.close, onPressed: onPressed);
}
