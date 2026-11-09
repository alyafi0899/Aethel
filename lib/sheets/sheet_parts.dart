import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../widgets/buttons.dart';

/// Header of a side panel: small uppercase label, big title, close button.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.label,
    required this.title,
    required this.onClose,
  });
  final String label, title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.sLabel.copyWith(letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(title, style: context.sH1.copyWith(fontSize: 18)),
              ],
            ),
          ),
          CloseIconButton(onPressed: onClose),
        ],
      ),
    );
  }
}

/// Sticky bottom bar with actions.
class SheetFooter extends StatelessWidget {
  const SheetFooter({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: children,
      ),
    );
  }
}

/// Grid of "LABEL / value / extra" cells.
class InfoCell {
  const InfoCell(
    this.label, {
    this.value,
    this.extra,
    this.badge,
    this.action,
    this.onAction,
  });
  final String label;
  final String? value;
  final String? extra;
  final Widget? badge;
  final String? action;
  final VoidCallback? onAction;
}

class InfoGrid extends StatelessWidget {
  const InfoGrid({
    super.key,
    required this.cells,
    this.columns = 2,
    this.bordered = true,
  });
  final List<InfoCell> cells;
  final int columns;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += columns) {
      final slice = cells.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++)
                Expanded(
                  child: j < slice.length
                      ? _cell(
                          context,
                          slice[j],
                          last: j == columns - 1,
                          firstRow: i == 0,
                        )
                      : const SizedBox(),
                ),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: bordered
          ? BoxDecoration(
              border: Border.all(color: context.c.border),
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _cell(
    BuildContext context,
    InfoCell c, {
    required bool last,
    required bool firstRow,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: last ? Colors.transparent : context.c.borderSoft,
          ),
          top: BorderSide(
            color: firstRow ? Colors.transparent : context.c.borderSoft,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.label, style: context.sLabel),
          const SizedBox(height: 5),
          if (c.badge != null) c.badge!,
          if (c.value != null) Text(c.value!, style: context.sStrong),
          if (c.extra != null) ...[
            const SizedBox(height: 2),
            Text(c.extra!, style: context.sSmall),
          ],
          if (c.action != null) ...[
            const SizedBox(height: 3),
            InkWell(
              onTap: c.onAction ?? () {},
              child: Text(
                c.action!,
                style: context.sSmall.copyWith(
                  color: context.c.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered dialog with a title/subtitle header and close button.
class ModalShell extends StatelessWidget {
  const ModalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.children,
    this.maxWidth = 590,
  });

  final String title, subtitle;
  final VoidCallback onClose;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(15),
      backgroundColor: context.c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.m.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.sH1.copyWith(fontSize: 19),
                          ),
                          const SizedBox(height: 4),
                          Text(subtitle, style: context.sSmall),
                        ],
                      ),
                    ),
                    CloseIconButton(onPressed: onClose),
                  ],
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Little green "slot available" style confirmation.
class InlineNote extends StatelessWidget {
  const InlineNote({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.check,
    this.tone = Tone.green,
  });
  final String title, message;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.soft(tone),
        borderRadius: BorderRadius.circular(context.m.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: c.fg(tone)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.sStrong.copyWith(color: c.fg(tone))),
                const SizedBox(height: 2),
                Text(message, style: context.sSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
