import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';
import '../widgets/toast.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppController>().data.profile;
    _name = TextEditingController(text: p.name);
    _desc = TextEditingController(text: p.description);
    _phone = TextEditingController(text: p.phone);
    _email = TextEditingController(text: p.email);
    for (final c in [_name, _desc]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    final p = data.profile;
    final c = context.c;

    final editor = AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Profile completeness', style: context.sStrong),
              ),
              Text(
                '${p.completeness}%',
                style: context.sStrong.copyWith(color: c.fg(Tone.green)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.completeness / 100,
              minHeight: 6,
              backgroundColor: c.border,
              color: c.fg(Tone.green),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add accessibility information to improve discovery',
            style: context.sSmall,
          ),
          const SizedBox(height: 16),
          FormField2('Clinic name', child: AppTextField(controller: _name)),
          const SizedBox(height: 12),
          FormField2(
            'Description',
            child: AppTextField(controller: _desc, maxLines: 3),
          ),
          const SizedBox(height: 12),
          FieldRow(
            children: [
              FormField2(
                'Public phone',
                child: AppTextField(controller: _phone),
              ),
              FormField2(
                'Support email',
                child: AppTextField(controller: _email),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FormField2(
            'Marketplace services',
            child: AppDropdown(
              items: const ['18 services published'],
              value: '18 services published',
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.soft(Tone.green),
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            ),
            child: Row(
              children: [
                Icon(AppIcons.check, size: 18, color: c.fg(Tone.green)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified facility',
                        style: context.sStrong.copyWith(
                          color: c.fg(Tone.green),
                        ),
                      ),
                      Text(
                        'Public profile meets PROMETHEON marketplace requirements.',
                        style: context.sSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final preview = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.soft(Tone.teal), c.soft(Tone.blue)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.building, size: 36, color: c.primary),
                const SizedBox(height: 8),
                Text(
                  'MARKETPLACE PREVIEW',
                  style: context.sLabel.copyWith(
                    color: c.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge('Open now', tone: Tone.green),
                const SizedBox(height: 10),
                Text(_name.text, style: context.sH1.copyWith(fontSize: 19)),
                const SizedBox(height: 6),
                Text(_desc.text, style: context.sBody),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(AppIcons.star, size: 16, color: c.fg(Tone.amber)),
                    const SizedBox(width: 5),
                    Text(p.rating, style: context.sStrong),
                    const SizedBox(width: 6),
                    Text(
                      '${p.reviews} verified reviews',
                      style: context.sSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in const [
                      '18 services',
                      '24 doctors',
                      'Online booking',
                    ])
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t, style: context.sSmall),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    'View available appointments',
                    kind: BtnKind.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          title: 'Public clinic profile',
          desc:
              'Control how ${data.facilityName} appears in patient marketplace discovery.',
          actions: [
            const AppButton('Preview profile'),
            AppButton(
              'Publish changes',
              kind: BtnKind.primary,
              onPressed: () => Toast.show(
                context,
                'Marketplace profile changes published successfully.',
              ),
            ),
          ],
        ),
        SplitLayout(
          leftFlex: 12,
          rightFlex: 8,
          gap: 12,
          left: editor,
          right: preview,
        ),
      ],
    );
  }
}
