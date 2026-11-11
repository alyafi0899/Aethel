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
import 'sheet_parts.dart';

/// Two-step "Create appointment" flow: details, then clinical intake.
class AppointmentFormDialog extends StatefulWidget {
  const AppointmentFormDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const AppointmentFormDialog(),
      );

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  static const _categories = [
    'Pain-related complaint',
    'Respiratory symptoms',
    'Gastrointestinal symptoms',
    'Neurological symptoms',
    'General / other',
  ];
  static const _sources = [
    'Patient self-reported',
    'Receptionist-assisted',
    'Clinical professional-assisted',
  ];

  int _step = 1;
  String? _patient;
  String _doctor = 'Unassigned';
  String _category = _categories.first;
  String _source = 'Receptionist-assisted';
  String? _error;
  final _complaint = TextEditingController();

  @override
  void dispose() {
    _complaint.dispose();
    super.dispose();
  }

  void _toStep2() {
    if (_patient == null) {
      setState(() => _error = 'Select a patient to continue.');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  void _save() {
    if (_patient == null) {
      setState(() {
        _error = 'Select a patient to continue.';
        _step = 1;
      });
      return;
    }
    if (_complaint.text.trim().isEmpty) {
      setState(() => _error = 'Add the patient’s primary complaint.');
      return;
    }
    final msg = context.read<AppController>().createAppointment(
          patient: _patient!,
          doctor: _doctor,
        );
    Toast.show(context, msg);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final noPatient = _error != null && _patient == null;
    final noComplaint =
        _error != null && _complaint.text.trim().isEmpty && _step == 2;

    Widget stepChip(int n, String title, String sub) {
      final active = _step == n;
      final done = _step > n;
      return Expanded(
        child: InkWell(
          onTap: () => n == 1 ? setState(() => _step = 1) : _toStep2(),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active || done ? c.primary : c.surface,
                  border: Border.all(
                    color: active || done ? c.primary : c.border,
                  ),
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(AppIcons.check, size: 12, color: Colors.white)
                    : Text(
                        '$n',
                        style: context.sStrong.copyWith(
                          color: active ? Colors.white : c.muted,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.sStrong,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sub,
                      style: context.sSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ModalShell(
      title: 'Create appointment',
      subtitle:
          'Appointment and linked clinical intake are created together without duplicate entry.',
      onClose: () => Navigator.of(context).pop(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              stepChip(1, 'Appointment details', 'Patient, service & schedule'),
              Container(
                width: 24,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: c.border,
              ),
              stepChip(
                2,
                'Patient Complaint & Symptom Intake',
                'Pre-consultation screening',
              ),
            ],
          ),
        ),
        if (_step == 1)
          ..._stepOne(context, noPatient)
        else
          ..._stepTwo(context, noComplaint),
      ],
    );
  }

  List<Widget> _stepOne(BuildContext context, bool noPatient) {
    return [
      FormSection(
        title: 'Patient & service',
        children: [
          FormField2(
            'Patient',
            required: true,
            error: noPatient ? _error : null,
            child: AppDropdown(
              items: const ['Amelia Stone', 'Jonah Kim'],
              value: _patient,
              hint: 'Search or select patient',
              hasError: noPatient,
              onChanged: (v) => setState(() {
                _patient = v;
                _error = null;
              }),
            ),
          ),
          FormField2(
            'Service',
            required: true,
            child: AppDropdown(
              items: const [
                'General consultation · 30 min · \$75',
                'Cardiology consultation · 45 min · \$180',
              ],
              value: 'General consultation · 30 min · \$75',
              onChanged: (_) {},
            ),
          ),
        ],
      ),
      FormSection(
        title: 'Schedule & allocation',
        children: [
          FieldRow(
            minChildWidth: 220,
            children: [
              FormField2(
                'Date',
                required: true,
                child: AppTextField(
                  controller: TextEditingController(text: '2025-06-17'),
                ),
              ),
              FormField2(
                'Time',
                required: true,
                child: AppDropdown(
                  items: const ['02:30 PM', '03:00 PM'],
                  value: '02:30 PM',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          FormField2(
            'Doctor',
            child: AppDropdown(
              items: const ['Unassigned', 'Dr. Noah Williams', 'Dr. Maya Chen'],
              value: _doctor,
              onChanged: (v) => setState(() => _doctor = v ?? 'Unassigned'),
            ),
          ),
          const InlineNote(
            title: 'Slot available',
            message:
                'Service, doctor, and resource availability checked. No conflicts found.',
          ),
        ],
      ),
      _footer([
        AppButton('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton(
          'Continue to intake',
          trailingIcon: AppIcons.arrow,
          kind: BtnKind.primary,
          onPressed: _toStep2,
        ),
      ]),
    ];
  }

  List<Widget> _stepTwo(BuildContext context, bool noComplaint) {
    final c = context.c;
    final isPain = _category == 'Pain-related complaint';
    const f = AppTextField.new;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DATA ENTRY MODE', style: context.sLabel),
            const SizedBox(height: 7),
            Segmented(
              options: _sources,
              selected: _source,
              onChanged: (v) => setState(() => _source = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(AppIcons.shield, size: 13, color: c.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Source: $_source · Author: ${_source == 'Patient self-reported' ? (_patient ?? '—') : 'Elena Cruz'}',
                    style: context.sSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      FormSection(
        children: [
          FieldRow(
            minChildWidth: 240,
            children: [
              FormField2(
                'Primary complaint',
                required: true,
                error: noComplaint ? _error : null,
                child: AppTextField(
                  controller: _complaint,
                  hint: 'Describe the main reason for this visit',
                  hasError: noComplaint,
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
              FormField2(
                'Symptom category',
                child: AppDropdown(
                  items: _categories,
                  value: _category,
                  onChanged: (v) =>
                      setState(() => _category = v ?? _categories.first),
                ),
              ),
              FormField2('Symptom duration', child: f(hint: 'e.g. 3 days')),
              FormField2(
                'Onset',
                child: AppDropdown(
                  items: const ['Unknown', 'Sudden', 'Gradual'],
                  value: 'Unknown',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ],
      ),
      if (isPain)
        FormSection(
          title: 'SOCRATES pain assessment',
          trailing: const StatusBadge('Conditional', tone: Tone.blue),
          children: [
            Text(
              'Shown because a pain-related complaint is selected. Optional fields may be completed later.',
              style: context.sSmall,
            ),
            FieldRow(
              minChildWidth: 150,
              children: [
                FormField2('Site', child: f(hint: 'Where is the pain?')),
                FormField2('Onset', child: f(hint: 'When did it begin?')),
                FormField2('Character', child: f(hint: 'How does it feel?')),
                FormField2('Radiation', child: f(hint: 'Does it spread?')),
                FormField2(
                  'Timing',
                  child: f(hint: 'Constant or intermittent?'),
                ),
                FormField2(
                  'Severity (0–10)',
                  child: f(hint: '0', keyboardType: TextInputType.number),
                ),
              ],
            ),
            FormField2(
              'Associated symptoms',
              child: f(hint: 'e.g. nausea, sweating, shortness of breath'),
            ),
            FormField2(
              'Exacerbating / relieving factors',
              child: f(hint: 'What makes it better or worse?'),
            ),
          ],
        )
      else
        FormSection(
          title: '$_category screening',
          trailing: const StatusBadge('Conditional', tone: Tone.blue),
          children: [
            Text(
              'Complaint-specific questions replace SOCRATES for this symptom category.',
              style: context.sSmall,
            ),
            FieldRow(
              minChildWidth: 220,
              children: [
                FormField2(
                  'Symptoms getting worse?',
                  child: AppDropdown(
                    items: const ['Not answered', 'Yes', 'No'],
                    value: 'Not answered',
                    onChanged: (_) {},
                  ),
                ),
                FormField2(
                  'Impact on normal activity?',
                  child: AppDropdown(
                    items: const ['Not answered', 'Mild', 'Moderate', 'Severe'],
                    value: 'Not answered',
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ],
        ),
      FormSection(
        title: 'Additional context',
        trailing: Text('OPTIONAL', style: context.sLabel),
        children: [
          FormField2(
            'Additional patient notes',
            child: f(
              hint:
                  'Any other information the patient wants the care team to know',
              maxLines: 2,
            ),
          ),
          FieldRow(
            minChildWidth: 240,
            children: [
              FormField2(
                'Relevant medical history',
                child: f(
                  hint: 'Previous conditions or relevant encounters',
                  maxLines: 2,
                ),
              ),
              FormField2(
                'Current medication and allergies',
                child: f(
                  hint: 'Medication, dose, and known allergies',
                  maxLines: 2,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.lock, size: 14, color: c.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Receptionist-assisted entry captures attributed patient-reported facts only. Clinical diagnosis and severity assignment require an authorized clinical role.',
                  style: context.sSmall,
                ),
              ),
            ],
          ),
        ],
      ),
      _footer([
        AppButton(
          'Back',
          kind: BtnKind.ghost,
          onPressed: () => setState(() => _step = 1),
        ),
        AppButton('Save draft', onPressed: () => Navigator.of(context).pop()),
        AppButton(
          'Create appointment & intake',
          kind: BtnKind.primary,
          onPressed: _save,
        ),
      ]),
    ];
  }

  Widget _footer(List<Widget> children) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.c.border)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: children,
        ),
      );
}
