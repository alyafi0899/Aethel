import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/context_ext.dart';
import '../widgets/buttons.dart';
import '../widgets/forms.dart';
import '../widgets/toast.dart';
import 'sheet_parts.dart';

class NotificationFormDialog extends StatefulWidget {
  const NotificationFormDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => const NotificationFormDialog(),
      );

  @override
  State<NotificationFormDialog> createState() => _NotificationFormDialogState();
}

class _NotificationFormDialogState extends State<NotificationFormDialog> {
  final _title = TextEditingController();
  String? _error;
  String _category = 'Operational Alert';
  String _priority = 'Normal';
  String _recipientType = 'Department';
  String _recipient = 'Cardiology';
  final Map<String, bool> _channels = {
    'In-app': true,
    'Push': true,
    'Email': false,
    'SMS': false,
  };

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _send() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'A title is required.');
      return;
    }
    Toast.show(
      context,
      'Notification NTF-02581 created and queued for 3 recipients.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ModalShell(
      title: 'Create notification',
      subtitle:
          'Create a traceable operational message for facility recipients.',
      onClose: () => Navigator.of(context).pop(),
      children: [
        FormSection(
          title: 'Message',
          children: [
            FormField2(
              'Notification title',
              required: true,
              error: _error,
              child: AppTextField(
                controller: _title,
                hint: 'Enter a clear, actionable title',
                hasError: _error != null,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            const FormField2(
              'Message body',
              required: true,
              child: AppTextField(
                hint:
                    'Describe the update and any action recipients should take.',
                maxLines: 3,
              ),
            ),
            FieldRow(
              minChildWidth: 220,
              children: [
                FormField2(
                  'Category',
                  child: AppDropdown(
                    items: const [
                      'Operational Alert',
                      'Doctor Notification',
                      'Appointment',
                    ],
                    value: _category,
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                ),
                FormField2(
                  'Priority',
                  child: AppDropdown(
                    items: const ['Normal', 'High', 'Critical'],
                    value: _priority,
                    onChanged: (v) =>
                        setState(() => _priority = v ?? _priority),
                  ),
                ),
              ],
            ),
          ],
        ),
        FormSection(
          title: 'Recipients & delivery',
          children: [
            FieldRow(
              minChildWidth: 220,
              children: [
                FormField2(
                  'Recipient type',
                  child: AppDropdown(
                    items: const [
                      'Department',
                      'Specific doctor',
                      'All active staff',
                    ],
                    value: _recipientType,
                    onChanged: (v) =>
                        setState(() => _recipientType = v ?? _recipientType),
                  ),
                ),
                FormField2(
                  'Recipient',
                  child: AppDropdown(
                    items: const ['Cardiology', 'Facility operations'],
                    value: _recipient,
                    onChanged: (v) =>
                        setState(() => _recipient = v ?? _recipient),
                  ),
                ),
              ],
            ),
            FormField2(
              'Delivery channels',
              child: Wrap(
                spacing: 18,
                children: [
                  for (final e in _channels.entries)
                    InkWell(
                      onTap: () => setState(() => _channels[e.key] = !e.value),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Checkbox(
                              value: e.value,
                              onChanged: (v) =>
                                  setState(() => _channels[e.key] = v ?? false),
                            ),
                          ),
                          Text(e.key, style: context.sBody),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.c.border)),
          ),
          child: Row(
            children: [
              const AppButton('Save draft', kind: BtnKind.ghost),
              const Spacer(),
              AppButton('Cancel', onPressed: () => Navigator.of(context).pop()),
              const SizedBox(width: 8),
              AppButton(
                'Send now',
                icon: AppIcons.send,
                kind: BtnKind.primary,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
