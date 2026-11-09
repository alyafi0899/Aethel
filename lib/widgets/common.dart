import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import 'buttons.dart';

/// White rounded card with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final inner = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? context.c.surface,
        borderRadius: BorderRadius.circular(context.m.radius),
        border: Border.all(color: borderColor ?? context.c.border),
      ),
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: inner),
            ),
    );
  }
}

/// Coloured status pill with a leading dot. Tone is inferred from the text
/// (see `badgeTone`) unless given explicitly.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key, this.tone});

  final String text;
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? badgeTone(text);
    final fg = context.c.fg(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.c.soft(t),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
            ),
            TextSpan(text: text),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.tt.labelSmall!.copyWith(
          color: fg,
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Initials in a circle.
class Avatar extends StatelessWidget {
  const Avatar(
    this.initials, {
    super.key,
    this.tone = Tone.blue,
    this.size = 30,
  });

  final String initials;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final solid = tone == Tone.navy;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: solid ? context.c.fg(Tone.navy) : context.c.soft(tone),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: context.tt.labelSmall!.copyWith(
          color: solid ? Colors.white : context.c.fg(tone),
          letterSpacing: 0,
          fontSize: size * .33,
        ),
      ),
    );
  }
}

/// Rounded tinted square holding an icon.
class IconBox extends StatelessWidget {
  const IconBox(
    this.icon, {
    super.key,
    this.tone = Tone.blue,
    this.size = 31,
    this.iconSize = 17,
  });

  final IconData icon;
  final Tone tone;
  final double size, iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.c.soft(tone),
        borderRadius: BorderRadius.circular(context.m.radiusSm),
      ),
      child: Icon(icon, size: iconSize, color: context.c.fg(tone)),
    );
  }
}

/// Page header: eyebrow, title, description + action buttons.
class PageHead extends StatelessWidget {
  const PageHead({
    super.key,
    this.eyebrow,
    required this.title,
    required this.desc,
    this.actions = const [],
  });

  final String? eyebrow;
  final String title, desc;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: context.sLabel.copyWith(
              color: context.c.primary.withValues(alpha: .8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(title, style: context.sH1),
        const SizedBox(height: 5),
        Text(desc, style: context.sSmall.copyWith(fontSize: 11.5)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 21),
      child: LayoutBuilder(
        builder: (context, bc) {
          final narrow = bc.maxWidth < 820;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Title + subtitle row used at the top of cards.
class CardHead extends StatelessWidget {
  const CardHead({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.sH2),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: context.sSmall),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Text link with an arrow ("View calendar →").
class LinkButton extends StatelessWidget {
  const LinkButton(this.label, {super.key, this.onTap, this.arrow = true});

  final String label;
  final VoidCallback? onTap;
  final bool arrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.sStrong.copyWith(
                color: context.c.primary,
                fontSize: 11.5,
              ),
            ),
            if (arrow) ...[
              const SizedBox(width: 4),
              Icon(AppIcons.arrow, size: 14, color: context.c.primary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Info strip: shield + title + message (+ optional action).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.shield,
    this.tone = Tone.blue,
    this.actionLabel,
    this.onAction,
  });

  final String title, message;
  final IconData icon;
  final Tone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final fg = context.c.fg(tone);
    final wide = !Breakpoints.isPhone(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: context.c.soft(tone),
        border: Border.all(color: fg.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(context.m.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.c.surface,
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            ),
            child: Icon(icon, size: 17, color: fg),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.sStrong.copyWith(color: fg)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: context.sSmall.copyWith(
                    color: fg.withValues(alpha: .85),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && wide) ...[
            const SizedBox(width: 10),
            AppButton(
              actionLabel!,
              compact: true,
              onPressed: onAction ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

/// Underlined horizontal tabs.
class TabsBar extends StatelessWidget {
  const TabsBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.counts = const {},
  });

  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, String> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.c.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            for (final t in tabs)
              InkWell(
                onTap: () => onChanged(t),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: t == selected
                            ? context.c.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        t,
                        style: context.sBody.copyWith(
                          color: t == selected
                              ? context.c.primary
                              : context.c.muted,
                          fontWeight: t == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (counts[t] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.soft(Tone.amber),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            counts[t]!,
                            style: context.tt.labelSmall!.copyWith(
                              color: context.c.fg(Tone.amber),
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bordered search input.
class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.controller,
    this.trailing,
    this.filled = true,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final Widget? trailing;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38 * context.m.control,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: filled ? context.c.surfaceAlt : context.c.surface,
        border: Border.all(color: context.c.border),
        borderRadius: BorderRadius.circular(context.m.radiusSm),
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 17, color: context.c.muted),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: context.sStrong.copyWith(fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Outlined filter chip ("All doctors ⌄").
class FilterPill extends StatelessWidget {
  const FilterPill(
    this.label, {
    super.key,
    this.icon,
    this.onTap,
    this.chevron = true,
    this.count,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool chevron;
  final String? count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.m.radiusSm),
        side: BorderSide(color: context.c.border),
      ),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(context.m.radiusSm),
        child: Container(
          height: 34 * context.m.control,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: context.c.muted),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: context.sBody.copyWith(fontWeight: FontWeight.w500),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: context.c.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count!,
                    style: context.tt.labelSmall!.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
              if (chevron) ...[
                const SizedBox(width: 4),
                Icon(AppIcons.chevronDown, size: 15, color: context.c.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of filters under a page header ("Today, Jun 17" + extras + More filters).
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.dateLabel,
    this.children = const [],
  });

  final String dateLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          FilterPill(dateLabel, icon: AppIcons.calendar),
          ...children,
          const FilterPill(
            'More filters',
            icon: AppIcons.filter,
            chevron: false,
          ),
        ],
      ),
    );
  }
}

/// Grid whose items share row height. `columns` receives the available width.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int Function(double width) columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bc) {
        final n = columns(bc.maxWidth).clamp(1, 12);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += n) {
          final slice = children.skip(i).take(n).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < n; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(
                      child: j < slice.length ? slice[j] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          );
          if (i + n < children.length) rows.add(SizedBox(height: spacing));
        }
        return Column(children: rows);
      },
    );
  }
}

/// Two panes side by side on wide screens, stacked on narrow ones.
class SplitLayout extends StatelessWidget {
  const SplitLayout({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.breakpoint = 900,
    this.gap = 14,
    this.stretch = false,
  });

  final Widget left, right;
  final int leftFlex, rightFlex;
  final double breakpoint, gap;

  /// Make both panes the same height (cards fill their pane).
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bc) {
        if (bc.maxWidth < breakpoint) {
          return Column(
            children: [
              left,
              SizedBox(height: gap),
              right,
            ],
          );
        }
        final row = Row(
          crossAxisAlignment: stretch
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: right),
          ],
        );
        return stretch ? IntrinsicHeight(child: row) : row;
      },
    );
  }
}

/// Big-number tile (used by summary strips).
class StatCard extends StatelessWidget {
  const StatCard(this.tile, {super.key, this.compact = false});

  final StatTile tile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tile.icon != null) ...[
            IconBox(tile.icon!, tone: tile.tone),
            const SizedBox(height: 10),
          ],
          Text(
            tile.value,
            style: context.sH1.copyWith(
              fontSize: 22,
              color: tile.icon == null && tile.tone != Tone.gray
                  ? context.c.fg(tile.tone)
                  : context.c.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(tile.label, style: context.sSmall),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.search,
  });

  final String title, message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: context.c.muted),
            const SizedBox(height: 10),
            Text(title, style: context.sH3),
            const SizedBox(height: 4),
            Text(message, style: context.sSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class Pagination extends StatelessWidget {
  const Pagination({super.key, required this.summary, this.pages = 3});

  final String summary;
  final int pages;

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, {bool active = false, bool disabled = false}) {
      return Opacity(
        opacity: disabled ? .45 : 1,
        child: Container(
          height: 28,
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? context.c.primary : context.c.surface,
            border: Border.all(
              color: active ? context.c.primary : context.c.border,
            ),
            borderRadius: BorderRadius.circular(context.m.radiusSm),
          ),
          child: Text(
            label,
            style: context.sBody.copyWith(
              color: active ? Colors.white : context.c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 12,
        children: [
          Text(summary, style: context.sSmall),
          Wrap(
            spacing: 5,
            children: [
              btn('Previous', disabled: true),
              for (var i = 1; i <= pages; i++) btn('$i', active: i == 1),
              btn('Next'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section heading inside a page / card.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.padding});
  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(text, style: context.sH3),
  );
}
