import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/context_ext.dart';
import '../core/theme/clinic_colors.dart';
import 'common.dart';

class GridColumn {
  const GridColumn(this.label, {this.flex = 1});
  final String label;
  final int flex;
}

class GridRowData {
  const GridRowData({required this.cells, this.onTap, this.highlight});
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? highlight;
}

/// Table that scrolls horizontally when narrower than [minWidth].
class DataGrid extends StatelessWidget {
  const DataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 900,
    this.empty,
  });

  final List<GridColumn> columns;
  final List<GridRowData> rows;
  final double minWidth;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && empty != null) return empty!;

    return LayoutBuilder(
      builder: (context, bc) {
        final width = max(bc.maxWidth, minWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _header(context),
                for (final r in rows) _row(context, r),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 34,
      color: context.c.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Text(
                col.label.toUpperCase(),
                style: context.sLabel,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, GridRowData r) {
    final content = Container(
      constraints: BoxConstraints(minHeight: context.m.rowHeight),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: r.highlight,
        border: Border(top: BorderSide(color: context.c.borderSoft)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            Expanded(
              flex: columns[i].flex,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: i < r.cells.length ? r.cells[i] : const SizedBox(),
              ),
            ),
        ],
      ),
    );
    if (r.onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: r.onTap, child: content),
    );
  }
}

/// Bold title with a muted sub-line.
class TwoLine extends StatelessWidget {
  const TwoLine(this.title, [this.subtitle, this.titleColor, Key? key])
      : super(key: key);

  final String title;
  final String? subtitle;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.sStrong.copyWith(color: titleColor),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.sSmall,
            ),
          ),
      ],
    );
  }
}

/// Avatar + two-line name cell.
class PersonCell extends StatelessWidget {
  const PersonCell({
    super.key,
    required this.initials,
    required this.title,
    this.subtitle,
    this.tone = Tone.blue,
  });

  final String initials, title;
  final String? subtitle;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Avatar(initials, tone: tone),
        const SizedBox(width: 9),
        Expanded(child: TwoLine(title, subtitle)),
      ],
    );
  }
}

/// Plain text cell.
class CellText extends StatelessWidget {
  const CellText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.sBody,
      );
}
