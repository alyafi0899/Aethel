import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.page});
  final AppPage page;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          title: page.label,
          desc: 'Facility-scoped administration and operational controls.',
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                IconBox(
                  AppIcons.settings,
                  tone: Tone.blue,
                  size: 62,
                  iconSize: 30,
                ),
                const SizedBox(height: 16),
                Text('${page.label} workspace', style: context.sH2),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    'This module inherits role-aware access, audit logging, loading, empty, and error recovery states from the PROMETHEON operating system.',
                    textAlign: TextAlign.center,
                    style: context.sSmall,
                  ),
                ),
                const SizedBox(height: 18),
                const AppButton('Open module settings', kind: BtnKind.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
