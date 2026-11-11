import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/toast.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  static const _tones = [
    Tone.teal,
    Tone.blue,
    Tone.violet,
    Tone.navy,
    Tone.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final services = context.watch<AppController>().data.services;
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Service catalog',
          desc:
              'Manage operational requirements, pricing, availability, and marketplace publishing.',
          actions: [
            AppButton(
              'Add service',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        AdaptiveGrid(
          columns: (w) => cols(w, wide: 3, mid: 2, narrow: 1),
          children: [
            for (var i = 0; i < services.length; i++)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 75,
                      color: c.soft(_tones[i % _tones.length]),
                      padding: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              i == 3 ? AppIcons.activity : AppIcons.service,
                              size: 25,
                              color: c.fg(_tones[i % _tones.length]),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: StatusBadge(services[i].status),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(services[i].category, style: context.sSmall),
                          const SizedBox(height: 3),
                          Text(services[i].name, style: context.sH2),
                          const SizedBox(height: 4),
                          Text(
                            '${services[i].duration} · ${services[i].doctors}',
                            style: context.sSmall,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  services[i].price,
                                  style: context.sH2.copyWith(fontSize: 16),
                                ),
                              ),
                              AppIconButton(
                                AppIcons.edit,
                                size: 30,
                                onPressed: () => Toast.show(
                                  context,
                                  '${services[i].name} opened for editing.',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
