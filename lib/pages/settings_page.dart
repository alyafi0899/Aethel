import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../core/theme/theme_config.dart';
import '../core/theme/theme_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';

/// Live theme editor. Everything here calls [ThemeController]; the same
/// setters are available from code.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _fonts = [
    'Inter',
    'Poppins',
    'Manrope',
    'Nunito',
    'Roboto',
    'DM Sans',
  ];

  @override
  Widget build(BuildContext context) {
    final tc = context.watch<ThemeController>();
    final cfg = tc.config;
    final c = context.c;

    Widget group(String title, String hint, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.sH3),
              const SizedBox(height: 2),
              Text(hint, style: context.sSmall),
              const SizedBox(height: 10),
              child,
            ],
          ),
        );

    Widget slider(
      double value,
      double min,
      double max,
      int divisions,
      ValueChanged<double> onChanged,
      String label,
    ) =>
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: c.primary,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: context.sStrong,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );

    final editor = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          group(
            'Brand colour',
            'Primary, accent and sidebar colours. Add palettes in theme_config.dart.',
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in BrandPalettes.all)
                  InkWell(
                    onTap: () => tc.setPalette(p),
                    borderRadius: BorderRadius.circular(context.m.radiusSm),
                    child: Container(
                      width: 104,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: p.id == cfg.palette.id ? c.primary : c.border,
                          width: p.id == cfg.palette.id ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(context.m.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (final col in [
                                p.sidebar,
                                p.primary,
                                p.accent,
                              ])
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(p.name, style: context.sStrong),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          group(
            'Mode',
            'Light, dark, or follow the device setting.',
            Segmented(
              options: const ['Light', 'Dark', 'System'],
              selected: switch (cfg.mode) {
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
                ThemeMode.system => 'System',
              },
              onChanged: (v) => tc.setMode(switch (v) {
                'Dark' => ThemeMode.dark,
                'System' => ThemeMode.system,
                _ => ThemeMode.light,
              }),
            ),
          ),
          group(
            'Corner radius',
            'Cards, buttons and inputs.',
            slider(
              cfg.radius,
              0,
              16,
              16,
              tc.setRadius,
              '${cfg.radius.round()} px',
            ),
          ),
          group(
            'Density',
            'Row heights, button heights and spacing.',
            Segmented(
              options: [for (final d in UiDensity.values) d.label],
              selected: cfg.density.label,
              onChanged: (v) => tc.setDensity(
                UiDensity.values.firstWhere((d) => d.label == v),
              ),
            ),
          ),
          group(
            'Font size',
            'Scales every text style.',
            slider(
              cfg.fontScale,
              0.85,
              1.25,
              8,
              tc.setFontScale,
              '${(cfg.fontScale * 100).round()}%',
            ),
          ),
          group(
            'Font family',
            'Loaded from Google Fonts.',
            SizedBox(
              width: 260,
              child: AppDropdown(
                items: _fonts,
                value: cfg.fontFamily,
                onChanged: (v) => tc.setFontFamily(v ?? 'Inter'),
              ),
            ),
          ),
          AppButton(
            'Reset to defaults',
            icon: AppIcons.refresh,
            onPressed: tc.reset,
          ),
        ],
      ),
    );

    final preview = AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live preview', style: context.sH2),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton('Primary', kind: BtnKind.primary),
              AppButton('Secondary'),
              AppButton('Danger', kind: BtnKind.danger),
            ],
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge('Confirmed'),
              StatusBadge('Pending'),
              StatusBadge('Checked-in'),
              StatusBadge('Failed'),
              StatusBadge('Draft'),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              IconBox(AppIcons.calendar, tone: Tone.blue),
              SizedBox(width: 8),
              IconBox(AppIcons.clock, tone: Tone.teal),
              SizedBox(width: 8),
              IconBox(AppIcons.alert, tone: Tone.amber),
              SizedBox(width: 8),
              IconBox(AppIcons.check, tone: Tone.green),
              SizedBox(width: 8),
              IconBox(AppIcons.doctor, tone: Tone.violet),
            ],
          ),
          const SizedBox(height: 14),
          const AppTextField(hint: 'Input field'),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Appearance',
          desc:
              'Customise the look of the whole workspace. Changes apply instantly.',
        ),
        SplitLayout(
          leftFlex: 3,
          rightFlex: 2,
          gap: 12,
          left: editor,
          right: preview,
        ),
      ],
    );
  }
}
