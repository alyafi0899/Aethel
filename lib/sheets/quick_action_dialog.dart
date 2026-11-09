import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../widgets/common.dart';
import '../widgets/toast.dart';
import 'appointment_form_dialog.dart';
import 'notification_form_dialog.dart';
import 'sheet_parts.dart';

class QuickActionDialog extends StatelessWidget {
  const QuickActionDialog({super.key, required this.parentContext});

  /// Context widget yang membuka dialog ini. Context ini tetap hidup setelah
  /// dialog tertutup, jadi dialog lanjutan dan toast dibuka darinya.
  final BuildContext parentContext;

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => QuickActionDialog(parentContext: context),
  );

  @override
  Widget build(BuildContext context) {
    final root = parentContext;

    Widget tile(
        IconData icon,
        Tone tone,
        String title,
        String sub,
        VoidCallback onTap,
        ) {
      return Material(
        color: context.c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.m.radius),
          side: BorderSide(color: context.c.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.m.radius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconBox(icon, tone: tone, size: 38, iconSize: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.sStrong),
                      const SizedBox(height: 2),
                      Text(sub, style: context.sSmall),
                    ],
                  ),
                ),
                Icon(AppIcons.chevron, size: 16, color: context.c.muted),
              ],
            ),
          ),
        ),
      );
    }

    void chain(void Function() next) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) => next());
    }

    return ModalShell(
      title: 'Quick action',
      subtitle: 'Start a common operational workflow.',
      maxWidth: 520,
      onClose: () => Navigator.of(context).pop(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              tile(
                AppIcons.calendar,
                Tone.blue,
                'New appointment',
                'Create a booking and validate availability',
                    () => chain(() => AppointmentFormDialog.show(root)),
              ),
              const SizedBox(height: 10),
              tile(
                AppIcons.bell,
                Tone.teal,
                'Send notification',
                'Notify doctors or facility staff',
                    () => chain(() => NotificationFormDialog.show(root)),
              ),
              const SizedBox(height: 10),
              tile(
                AppIcons.users,
                Tone.violet,
                'Register patient',
                'Create a local facility registration',
                    () => chain(
                      () => Toast.show(root, 'Patient registration workflow opened.'),
                ),
              ),
              const SizedBox(height: 10),
              tile(
                AppIcons.wallet,
                Tone.amber,
                'Create invoice',
                'Bill a service or appointment',
                    () => chain(() => Toast.show(root, 'Invoice builder opened.')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}