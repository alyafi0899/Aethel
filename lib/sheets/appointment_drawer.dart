import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/side_panel.dart';
import '../widgets/toast.dart';
import 'sheet_parts.dart';

class AppointmentDrawer extends StatelessWidget {
  const AppointmentDrawer({super.key, required this.id});
  final String id;

  static Future<void> show(BuildContext context, String id) =>
      showSidePanel(context, builder: (_) => AppointmentDrawer(id: id));

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final a = ctrl.appointmentById(id);
    if (a == null) return const SizedBox();
    final c = context.c;

    final (action, next) = switch (a.status) {
      'Pending Confirmation' => ('Confirm appointment', 'Confirmed'),
      'Awaiting Check-in' => ('Check in patient', 'Checked-in'),
      'Checked-in' => ('Move to waiting', 'Waiting for Doctor'),
      'Waiting for Doctor' => ('Start consultation', 'In Consultation'),
      _ => ('Complete consultation', 'Completed'),
    };
    final isChest = a.id.endsWith('048');

    const steps = [
      'Booking and clinical intake created',
      'Screening notification queued',
      'Appointment confirmed',
      'Patient checked in',
    ];

    return Column(
      children: [
        SheetHeader(
          label: 'APPOINTMENT DETAILS',
          title: a.id,
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  StatusBadge(a.status),
                  const SizedBox(width: 10),
                  Text('Updated 8 min ago', style: context.sSmall),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Avatar(a.initials, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.patient, style: context.sH2),
                        const SizedBox(height: 2),
                        Text(
                          'Global ID PT-009821 · MRN-PC-20418',
                          style: context.sSmall,
                        ),
                      ],
                    ),
                  ),
                  const AppIconButton(AppIcons.chevron),
                ],
              ),
              const SizedBox(height: 16),
              InfoGrid(
                cells: [
                  InfoCell(
                    'DATE & TIME',
                    value: a.date,
                    extra: '${a.time} · 45 minutes',
                  ),
                  InfoCell('SERVICE', value: a.service, extra: 'In-person'),
                  InfoCell(
                    'ASSIGNED DOCTOR',
                    value: a.doctor,
                    action: 'Change assignment',
                  ),
                  InfoCell('ROOM', value: a.room, action: 'Reallocate'),
                  InfoCell(
                    'BOOKING SOURCE',
                    value: a.source,
                    extra: 'Created Jun 15, 4:32 PM',
                  ),
                  InfoCell(
                    'PAYMENT',
                    badge: StatusBadge(a.payment),
                    extra: r'INV-20481 · $180.00',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.soft(Tone.blue).withValues(alpha: .5),
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(context.m.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LINKED CLINICAL INTAKE',
                                style: context.sLabel,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Patient complaint & symptom intake',
                                style: context.sH3,
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(
                          'Screening submitted',
                          tone: Tone.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoGrid(
                      bordered: false,
                      cells: [
                        InfoCell(
                          'PRIMARY COMPLAINT',
                          value: isChest
                              ? 'Central chest pain'
                              : 'Symptoms reported before consultation',
                        ),
                        InfoCell(
                          'DURATION',
                          value: isChest ? '45 minutes' : '3 days',
                        ),
                        InfoCell(
                          'DATA SOURCE',
                          value: a.source == 'Patient app'
                              ? 'Patient self-reported'
                              : 'Receptionist-assisted',
                        ),
                        InfoCell(
                          'SCREENING',
                          value: isChest
                              ? 'Escalated · Urgent'
                              : 'Ready for review',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const LinkButton('Open linked screening'),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(AppIcons.lock, size: 11, color: c.muted),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Intake INT-250617-084 remains linked to this appointment and future clinical encounter.',
                            style: context.sSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('ADDITIONAL PATIENT NOTE', style: context.sLabel),
              const SizedBox(height: 5),
              Text(
                'Follow-up appointment. Patient reports intermittent discomfort over the past week.',
                style: context.sBody,
              ),
              const SizedBox(height: 20),
              Text('Appointment & screening lifecycle', style: context.sH3),
              const SizedBox(height: 10),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < 2 ? c.fg(Tone.green) : c.surface,
                          border: Border.all(
                            color: i < 2 ? c.fg(Tone.green) : c.border,
                            width: 1.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: i < 2
                            ? const Icon(
                                AppIcons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : Text('${i + 1}', style: context.sSmall),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(steps[i], style: context.sStrong),
                            Text(
                              i < 2
                                  ? 'Elena Cruz · Jun 16, 09:14 AM'
                                  : 'Pending operational action',
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
        ),
        SheetFooter(
          children: [
            const AppButton('More actions'),
            AppButton(
              action,
              icon: AppIcons.check,
              kind: BtnKind.primary,
              onPressed: () =>
                  Toast.show(context, ctrl.updateStatus(a.id, next)),
            ),
          ],
        ),
      ],
    );
  }
}
