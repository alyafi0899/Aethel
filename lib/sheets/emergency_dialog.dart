import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';
import 'sheet_parts.dart';

/// Red-flag safety dialog. Resolves to `true` when the user escalates.
class EmergencyDialog extends StatelessWidget {
  const EmergencyDialog({super.key, required this.screening});
  final Screening screening;

  static Future<bool?> show(BuildContext context, Screening s) =>
      showDialog<bool>(
        context: context,
        barrierColor: const Color(0xA00E1D2A),
        builder: (_) => EmergencyDialog(screening: s),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final red = c.fg(Tone.red);
    final s = screening;

    return Dialog(
      insetPadding: const EdgeInsets.all(15),
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.m.radiusLg),
        side: BorderSide(color: red.withValues(alpha: .5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
                color: c.soft(Tone.red),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(AppIcons.alert, size: 27, color: red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SAFETY ALERT',
                            style: context.sLabel.copyWith(
                              color: red,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Potential emergency symptoms reported',
                            style: context.sH1.copyWith(
                              fontSize: 18,
                              color: red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(context.m.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Avatar(s.initials),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.patient, style: context.sStrong),
                                Text(
                                  '${s.appointment} · ${s.complaint} · ${s.duration}',
                                  style: context.sSmall,
                                ),
                              ],
                            ),
                          ),
                          const StatusBadge('Urgent', tone: Tone.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Immediate action guidance', style: context.sH3),
                    const SizedBox(height: 8),
                    for (final (i, t) in const [
                      'If the patient is on site, keep them with a staff member and activate the facility emergency response protocol now.',
                      'If the patient is remote, advise them to contact local emergency services immediately. Do not ask them to wait for a routine appointment.',
                      'Escalate to the on-call authorized clinical professional and document the response.',
                    ].indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              child: Text('${i + 1}.', style: context.sStrong),
                            ),
                            Expanded(child: Text(t, style: context.sBody)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    InlineNote(
                      icon: AppIcons.shield,
                      tone: Tone.gray,
                      title: 'No diagnosis',
                      message:
                      'This alert identifies reported red-flag symptoms only. It does not provide a diagnosis and must not be used to dismiss or downgrade emergency symptoms.',
                    ),
                    const SizedBox(height: 14),
                    FormField2(
                      'Escalation note',
                      child: AppTextField(
                        controller: TextEditingController(
                          text:
                          'Central chest pressure with radiation, shortness of breath, sweating, and severity 8/10. Immediate clinical assessment requested.',
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(AppIcons.clock, size: 16, color: c.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety event recorded',
                                style: context.sStrong,
                              ),
                              Text(
                                'Jun 17, 2025 · 10:43:12 AM · Event EVT-88421',
                                style: context.sSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    AppButton(
                      'Return to review',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    AppButton(
                      'Escalate to emergency clinical team',
                      icon: AppIcons.alert,
                      kind: BtnKind.danger,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}