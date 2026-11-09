import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class OperationsPage extends StatelessWidget {
  const OperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final states = context.watch<AppController>().data.opsStates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Operations overview',
          desc:
              'Real-time facility health, bottlenecks, and recovery workflows.',
        ),
        AdaptiveGrid(
          columns: (w) => cols(w, wide: 3, mid: 2, narrow: 1),
          children: [
            for (final s in states)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconBox(
                      s.tone == Tone.red ? AppIcons.alert : AppIcons.activity,
                      tone: s.tone,
                      size: 38,
                      iconSize: 19,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: context.sStrong),
                          const SizedBox(height: 5),
                          StatusBadge(s.status, tone: s.tone),
                          const SizedBox(height: 5),
                          Text(s.detail, style: context.sSmall),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevron, size: 16, color: context.c.muted),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
