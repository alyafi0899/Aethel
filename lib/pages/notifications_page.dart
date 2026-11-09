import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../sheets/notification_form_dialog.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _tabs = [
    'Inbox',
    'History',
    'Scheduled',
    'Drafts',
    'Failed delivery',
  ];
  String _tab = 'History';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    final q = _query.toLowerCase();
    final items = data.notifications
        .where(
          (n) => _tab != 'Failed delivery' || n.delivery.contains('Failed'),
        )
        .where((n) => (n.title + n.id + n.recipient).toLowerCase().contains(q))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          title: 'Notification center',
          desc: 'Create, monitor, and audit event-driven operational communications.',
          actions: [
            const AppButton('Templates', icon: AppIcons.service),
            AppButton(
              'Create notification',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
              onPressed: () => NotificationFormDialog.show(context),
            ),
          ],
        ),
        AdaptiveGrid(
          spacing: 10,
          columns: (w) => cols(w, wide: 5, mid: 3, narrow: 2),
          children: [for (final t in data.notificationStats) StatCard(t)],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabsBar(
                tabs: _tabs,
                selected: _tab,
                counts: const {'Failed delivery': '7'},
                onChanged: (t) => setState(() => _tab = t),
              ),
              const _LifecycleStrip(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: SearchBox(
                        hint: 'Search notifications',
                        filled: false,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const FilterPill('All categories'),
                    const FilterPill('All channels'),
                  ],
                ),
              ),
              DataGrid(
                minWidth: 980,
                columns: const [
                  GridColumn('Notification', flex: 15),
                  GridColumn('Recipient', flex: 15),
                  GridColumn('Category', flex: 10),
                  GridColumn('Delivery', flex: 11),
                  GridColumn('Read status', flex: 8),
                  GridColumn('Sent at', flex: 8),
                  GridColumn('', flex: 3),
                ],
                empty: const EmptyState(
                  title: 'No notifications found',
                  message:
                      'There are no notifications matching the current view.',
                ),
                rows: [
                  for (final n in items)
                    GridRowData(
                      cells: [
                        TwoLine(n.title, '${n.id} · ${data.userName}'),
                        TwoLine(n.recipient, 'In-app + Push'),
                        CellText(n.category),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(n.delivery),
                        ),
                        CellText(n.read),
                        CellText(n.sentAt),
                        const AppIconButton(AppIcons.more, size: 30),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LifecycleStrip extends StatelessWidget {
  const _LifecycleStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    Widget step(
      String label,
      IconData? icon, {
      bool done = false,
      bool active = false,
    }) {
      final color = done ? c.fg(Tone.green) : (active ? c.primary : c.muted);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.sBody.copyWith(
              color: color,
              fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      );
    }

    Widget sep() => Container(
      width: 22,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: c.border,
    );

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Row(
          children: [
            step('Event created', AppIcons.check, done: true),
            sep(),
            step('Notification queued', AppIcons.check, done: true),
            sep(),
            step('Delivery attempted', AppIcons.refresh, active: true),
            sep(),
            step('Recipient read', null),
            const SizedBox(width: 24),
            Text(
              'Lifecycle statuses are tracked independently',
              style: context.sSmall,
            ),
          ],
        ),
      ),
    );
  }
}
