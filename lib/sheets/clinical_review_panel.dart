import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';
import '../widgets/side_panel.dart';
import '../widgets/toast.dart';
import 'emergency_dialog.dart';
import 'sheet_parts.dart';

class ClinicalReviewPanel extends StatefulWidget {
  const ClinicalReviewPanel({super.key, required this.screening});
  final Screening screening;

  static Future<void> show(BuildContext context, Screening s) => showSidePanel(
    context,
    width: 620,
    builder: (_) => ClinicalReviewPanel(screening: s),
  );

  @override
  State<ClinicalReviewPanel> createState() => _ClinicalReviewPanelState();
}

class _ClinicalReviewPanelState extends State<ClinicalReviewPanel> {
  static const _tabs = [
    'Review',
    'Screening Detail',
    'Triage History',
    'Data Mapping',
  ];
  String _tab = 'Review';
  late bool _reviewing = widget.screening.status != 'New Screening';

  Screening get s => widget.screening;

  Future<void> _openEmergency() async {
    final escalate = await EmergencyDialog.show(context, s);
    if (escalate == true && mounted) {
      Toast.show(
        context,
        'Emergency escalation ${s.id} sent to the on-call clinical team and audit event recorded.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final author = s.source.contains('Patient') ? s.patient : 'Elena Cruz';

    return Column(
      children: [
        SheetHeader(
          label: 'CLINICAL TRIAGE REVIEW',
          title: s.id,
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            children: [
              if (s.redFlag)
                Material(
                  color: c.soft(Tone.red),
                  child: InkWell(
                    onTap: _openEmergency,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.alert,
                              size: 19,
                              color: c.fg(Tone.red),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Potential emergency red flag detected',
                                  style: context.sStrong.copyWith(
                                    color: c.fg(Tone.red),
                                  ),
                                ),
                                Text(
                                  'Chest pain with associated shortness of breath requires immediate clinical escalation.',
                                  style: context.sSmall.copyWith(
                                    color: c
                                        .fg(Tone.red)
                                        .withValues(alpha: .85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            AppIcons.chevron,
                            size: 18,
                            color: c.fg(Tone.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(s.initials, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.patient, style: context.sH2),
                              const SizedBox(height: 2),
                              Text(
                                'PT-009821 · MRN-PC-20418 · DOB 14 Mar 1982',
                                style: context.sSmall,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(s.priority),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InfoGrid(
                      columns: 4,
                      cells: [
                        InfoCell('APPOINTMENT', value: s.appointment),
                        InfoCell('SUBMITTED', value: 'Today, ${s.submitted}'),
                        InfoCell('DATA SOURCE', value: s.source),
                        InfoCell('AUTHOR', value: author),
                      ],
                    ),
                  ],
                ),
              ),
              TabsBar(
                tabs: _tabs,
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: switch (_tab) {
                  'Review' => _review(context),
                  'Screening Detail' => _detail(context, author),
                  'Triage History' => _history(context),
                  _ => _mapping(context),
                },
              ),
            ],
          ),
        ),
        SheetFooter(
          children: !_reviewing
              ? [
                  AppButton(
                    'Assign clinical reviewer',
                    onPressed: () => Toast.show(
                      context,
                      'Reviewer assignment opened for ${s.id}.',
                    ),
                  ),
                  AppButton(
                    'Start review',
                    kind: BtnKind.primary,
                    onPressed: () {
                      setState(() => _reviewing = true);
                      Toast.show(
                        context,
                        'Review started for ${s.id}. Reviewer and timestamp recorded.',
                      );
                    },
                  ),
                ]
              : [
                  const AppButton('Request information', compact: true),
                  AppButton(
                    'Assign reviewer',
                    compact: true,
                    onPressed: () => Toast.show(
                      context,
                      'Reviewer assignment updated for ${s.id}; notification and audit event created.',
                    ),
                  ),
                  AppButton(
                    'Escalate to doctor',
                    compact: true,
                    onPressed: _openEmergency,
                  ),
                  const AppButton(
                    'Record assessment',
                    icon: AppIcons.edit,
                    compact: true,
                  ),
                  AppButton(
                    'Complete review',
                    icon: AppIcons.check,
                    compact: true,
                    kind: BtnKind.primary,
                    onPressed: () => Toast.show(
                      context,
                      '${s.id} marked complete. triage_status_history and audit_logs records created.',
                    ),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    Widget child, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.sH3)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _textCell(
    BuildContext context,
    String label,
    String text, {
    Tone? tone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone != null ? context.c.soft(tone) : null,
        border: Border.all(color: context.c.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.sLabel.copyWith(
              color: tone != null ? context.c.fg(tone) : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(text, style: context.sBody.copyWith(color: context.c.text)),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) {
    const socrates = [
      ('Site', 'Central chest, behind sternum'),
      ('Onset', 'Sudden, while walking upstairs'),
      ('Character', 'Pressure / tightness'),
      ('Radiation', 'Left shoulder and jaw'),
      ('Associated symptoms', 'Shortness of breath, sweating'),
      ('Timing', 'Continuous for 45 minutes'),
      ('Exacerbating / relieving', 'Worse with exertion; no relief at rest'),
      ('Severity', '8 / 10'),
    ];
    const vitals = [
      ('BP', '154/96', 'mmHg'),
      ('HR', '104', 'bpm'),
      ('SpO₂', '94', '%'),
      ('Temp', '37.1', '°C'),
      ('RR', '22', '/min'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          context,
          'Complaint summary',
          InfoGrid(
            cells: [
              InfoCell('PRIMARY COMPLAINT', value: s.complaint),
              InfoCell('SYMPTOM DURATION', value: s.duration),
              const InfoCell('ONSET', value: 'Sudden'),
              InfoCell('RECORDED', value: 'Jun 17 · ${s.submitted}'),
            ],
          ),
          trailing: StatusBadge('${s.completion}% complete'),
        ),
        _section(
          context,
          'SOCRATES pain assessment',
          LayoutBuilder(
            builder: (context, bc) {
              final two = bc.maxWidth > 380;
              final items = [
                for (final x in socrates) _textCell(context, x.$1, x.$2),
              ];
              if (!two) return Column(children: items);
              return Column(
                children: [
                  for (var i = 0; i < items.length; i += 2)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: items[i]),
                          Expanded(child: items[i + 1]),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          trailing: Text(
            'Conditionally displayed · Pain complaint',
            style: context.sSmall,
          ),
        ),
        _section(
          context,
          'History, medication & allergies',
          Column(
            children: [
              _textCell(
                context,
                'Relevant medical history',
                'Hypertension diagnosed 2020. Previous similar, milder episode approximately 3 months ago.',
              ),
              _textCell(
                context,
                'Current medication',
                'Amlodipine 5 mg once daily.',
              ),
              _textCell(
                context,
                'Known allergies',
                'Penicillin — rash',
                tone: Tone.red,
              ),
            ],
          ),
        ),
        _section(
          context,
          'Vital signs',
          Row(
            children: [
              for (final v in vitals)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.c.borderSoft),
                    ),
                    child: Column(
                      children: [
                        Text(v.$1, style: context.sLabel),
                        const SizedBox(height: 4),
                        Text(v.$2, style: context.sH2),
                        Text(v.$3, style: context.sSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          trailing: Text(
            'Recorded by Nurse Olivia Park · 10:46 AM',
            style: context.sSmall,
          ),
        ),
        _section(
          context,
          'Previous relevant encounters',
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: context.c.border),
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            ),
            child: Row(
              children: [
                Icon(AppIcons.calendar, size: 18, color: context.c.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cardiology consultation · Mar 04, 2025',
                        style: context.sStrong,
                      ),
                      Text(
                        'Prometheon Central · Dr. Maya Chen · Summary access authorized',
                        style: context.sSmall,
                      ),
                    ],
                  ),
                ),
                const LinkButton('View summary', arrow: false),
              ],
            ),
          ),
        ),
        const NoticeBanner(
          title: 'Clinical assessment permission required',
          message: 'Only Doctor, Nurse, or authorized Clinical Reviewer roles can record triage priority, disposition, or clinical assessment. Receptionists may add attributed patient-reported facts only.',
        ),
      ],
    );
  }

  Widget _detail(BuildContext context, String author) {
    const qa = [
      ('Have symptoms worsened?', 'Yes, during physical activity'),
      ('Shortness of breath?', 'Yes'),
      ('Loss of consciousness?', 'No'),
      ('Nausea or vomiting?', 'Mild nausea'),
      ('Recent injury or procedure?', 'No'),
      (
        'Additional patient notes',
        'Symptoms began on the walk from the parking area.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          context,
          'Screening questionnaire',
          Column(
            children: [
              for (final x in qa)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: context.c.borderSoft),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(x.$1, style: context.sBody)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          x.$2,
                          style: context.sStrong,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: const StatusBadge('Submitted', tone: Tone.green),
        ),
        _section(
          context,
          'Provenance',
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: context.c.border),
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.shield, size: 18, color: context.c.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.source, style: context.sStrong),
                      const SizedBox(height: 2),
                      Text(
                        'Authored by $author · Submitted Jun 17, 2025 at ${s.submitted}',
                        style: context.sBody,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'clinical_intakes.intake_id → screening_sessions.clinical_intake_id',
                        style: context.sSmall.copyWith(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _history(BuildContext context) {
    final history = [
      (
        'Screening submitted',
        '${s.source} · ${s.submitted}',
        'screening.submitted',
      ),
      (
        'Red-flag rule matched',
        'System safety rule · 10:43 AM',
        'screening.red_flag_detected',
      ),
      (
        'Clinical reviewer assigned',
        'Dr. Maya Chen · 10:45 AM',
        'triage.reviewer_assigned',
      ),
      ('Review started', 'Dr. Maya Chen · 10:47 AM', 'triage.review_started'),
    ];
    final c = context.c;
    return _section(
      context,
      'Triage status history',
      Column(
        children: [
          for (var i = 0; i < history.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == history.length - 1
                          ? c.primary
                          : c.fg(Tone.green),
                      shape: BoxShape.circle,
                    ),
                    child: i < history.length - 1
                        ? const Icon(
                            AppIcons.check,
                            size: 11,
                            color: Colors.white,
                          )
                        : Text(
                            '${i + 1}',
                            style: context.sLabel.copyWith(
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history[i].$1, style: context.sStrong),
                        Text(history[i].$2, style: context.sSmall),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceAlt,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            history[i].$3,
                            style: context.sSmall.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Text('Immutable operational timeline', style: context.sSmall),
    );
  }

  Widget _mapping(BuildContext context) {
    const rows = [
      (
        'Create appointment + intake',
        'appointments.create',
        '{ patient_id, slot_id, intake, answers[] }',
        'appointments, clinical_intakes, intake_answers, screening_sessions',
        'appointment.intake_created',
      ),
      (
        'Start review',
        'clinical_intakes.review',
        '{ screening_session_id, reviewer_id }',
        'screening_sessions, triage_status_history',
        'triage.review_started',
      ),
      (
        'Assign reviewer',
        'triage.assign_reviewer',
        '{ screening_session_id, reviewer_id }',
        'screening_sessions, notifications',
        'triage.reviewer_assigned',
      ),
      (
        'Request information',
        'clinical_intakes.request_info',
        '{ question, recipient_id }',
        'screening_sessions, notifications',
        'triage.info_requested',
      ),
      (
        'Escalate to doctor',
        'triage.escalate',
        '{ reason, doctor_id, priority }',
        'triage_assessments, triage_status_history',
        'triage.escalated',
      ),
      (
        'Record assessment',
        'triage.assess',
        '{ priority, disposition, notes }',
        'triage_assessments',
        'triage.assessment_recorded',
      ),
      (
        'Complete review',
        'triage.complete',
        '{ assessment_id, outcome }',
        'screening_sessions, triage_status_history',
        'triage.completed',
      ),
    ];
    TextStyle mono() => context.sSmall.copyWith(
      fontFamily: 'monospace',
      fontSize: 10,
      color: context.c.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          context,
          'Backend action contract',
          AppCard(
            child: DataGrid(
              minWidth: 760,
              columns: const [
                GridColumn('Action', flex: 3),
                GridColumn('Permission', flex: 4),
                GridColumn('Input payload', flex: 5),
                GridColumn('Tables / audit event', flex: 5),
              ],
              rows: [
                for (final r in rows)
                  GridRowData(
                    cells: [
                      Text(r.$1, style: context.sStrong),
                      Text(r.$2, style: mono()),
                      Text(r.$3, style: mono()),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$4, style: context.sSmall),
                          const SizedBox(height: 2),
                          Text(
                            r.$5,
                            style: mono().copyWith(color: context.c.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          trailing: Text(
            'Supabase PostgreSQL + audited RPC',
            style: context.sSmall,
          ),
        ),
        const NoticeBanner(
          icon: AppIcons.lock,
          title: 'Expected output',
          message: 'Every mutation returns the updated screening status, server timestamp, actor profile, linked appointment and encounter IDs, notification delivery records when applicable, and an immutable audit event.',
        ),
      ],
    );
  }
}
