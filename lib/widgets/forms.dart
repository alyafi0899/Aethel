import 'package:flutter/material.dart';
import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';

/// Label + control + optional error message.
class FormField2 extends StatelessWidget {
  const FormField2(
    this.label, {
    super.key,
    required this.child,
    this.required = false,
    this.error,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.c.fg(Tone.red)),
                ),
            ],
          ),
          style: context.sStrong.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 6),
        child,
        if (error != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(AppIcons.alert, size: 12, color: context.c.fg(Tone.red)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  error!,
                  style: context.sSmall.copyWith(color: context.c.fg(Tone.red)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.maxLines = 1,
    this.hasError = false,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool hasError;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final red = context.c.fg(Tone.red);
    OutlineInputBorder b(Color col) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.m.radiusSm),
          borderSide: BorderSide(color: col),
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: context.sStrong.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: hint,
        enabledBorder: hasError ? b(red) : null,
        focusedBorder: hasError ? b(red) : null,
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.hasError = false,
  });

  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40 * context.m.control,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(context.m.radiusSm),
        border: Border.all(
          color: hasError ? context.c.fg(Tone.red) : context.c.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : null,
          isExpanded: true,
          hint: Text(hint ?? 'Select', style: context.sSmall),
          icon: Icon(AppIcons.chevronDown, size: 18, color: context.c.muted),
          dropdownColor: context.c.surface,
          style: context.sStrong.copyWith(fontWeight: FontWeight.w400),
          items: [
            for (final i in items)
              DropdownMenuItem(
                value: i,
                child: Text(i, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Two / three fields in a row on wide layouts, stacked on narrow ones.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children, this.minChildWidth = 200});

  final List<Widget> children;
  final double minChildWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bc) {
        final n = (bc.maxWidth / minChildWidth).floor().clamp(
              1,
              children.length,
            );
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += n) {
          final slice = children.skip(i).take(n).toList();
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < n; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child: j < slice.length ? slice[j] : const SizedBox(),
                  ),
                ],
              ],
            ),
          );
          if (i + n < children.length) rows.add(const SizedBox(height: 12));
        }
        return Column(children: rows);
      },
    );
  }
}

/// Grouped block of form fields with a heading.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    this.title,
    required this.children,
    this.trailing,
  });

  final String? title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.c.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: Text(title!, style: context.sH3)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Little segmented control (data-entry mode, detail tabs ...).
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final o in options)
          InkWell(
            onTap: () => onChanged(o),
            borderRadius: BorderRadius.circular(context.m.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: o == selected
                    ? context.c.soft(Tone.blue)
                    : context.c.surface,
                border: Border.all(
                  color: o == selected ? context.c.primary : context.c.border,
                ),
                borderRadius: BorderRadius.circular(context.m.radiusSm),
              ),
              child: Text(
                o,
                style: context.sBody.copyWith(
                  color: o == selected
                      ? context.c.primary
                      : context.c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
