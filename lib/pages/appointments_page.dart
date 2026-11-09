import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../sheets/appointment_drawer.dart';
import '../sheets/appointment_form_dialog.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  static const _tabs = [
    'All appointments',
    'Today',
    'Pending',
    'Upcoming',
    'Completed',
    'Cancelled',
  ];

  String _tab = _tabs.first;
  String _localSearch = '';
  bool _sortAsc = true;

  List<Appointment> _rows(AppController ctrl) {
    final q = (_localSearch.isNotEmpty ? _localSearch : ctrl.globalSearch)
        .toLowerCase();
    var rows = ctrl.appointments
        .where((a) => (a.patient + a.id + a.doctor).toLowerCase().contains(q))
        .toList();
    switch (_tab) {
      case 'Pending':
        rows = rows.where((a) => a.status.contains('Pending')).toList();
      case 'Today':
        rows = rows.where((a) => a.date.contains('Jun 17')).toList();
      case 'Upcoming':
        rows = rows
            .where(
              (a) =>
                  !a.status.contains('Completed') &&
                  !a.status.contains('Cancelled'),
            )
            .toList();
      case 'Completed':
        rows = rows.where((a) => a.status.contains('Completed')).toList();
      case 'Cancelled':
        rows = rows.where((a) => a.status.contains('Cancelled')).toList();
    }
    rows.sort(
      (a, b) => _sortAsc ? a.time.compareTo(b.time) : b.time.compareTo(a.time),
    );
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final data = ctrl.data;
    final rows = _rows(ctrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          title: 'Appointment management',
          desc: 'Manage bookings, check-ins, room allocation, and appointment lifecycle.',
          actions: [
            const AppButton('Export', icon: AppIcons.download),
            AppButton(
              'New appointment',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
              onPressed: () => AppointmentFormDialog.show(context),
            ),
          ],
        ),
        _SummaryStrip(tiles: data.appointmentSummary),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabsBar(
                tabs: _tabs,
                selected: _tab,
                counts: const {'Pending': '12'},
                onChanged: (t) => setState(() => _tab = t),
              ),
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
                        hint: 'Search patient or reference',
                        filled: false,
                        onChanged: (v) => setState(() => _localSearch = v),
                      ),
                    ),
                    const FilterPill('All doctors'),
                    const FilterPill('All services'),
                    FilterPill(
                      'Time ${_sortAsc ? '↑' : '↓'}',
                      chevron: false,
                      onTap: () => setState(() => _sortAsc = !_sortAsc),
                    ),
                    const FilterPill(
                      'Filters',
                      icon: AppIcons.filter,
                      chevron: false,
                      count: '2',
                    ),
                  ],
                ),
              ),
              DataGrid(
                minWidth: 980,
                columns: const [
                  GridColumn('Appointment', flex: 14),
                  GridColumn('Patient', flex: 15),
                  GridColumn('Date & time', flex: 11),
                  GridColumn('Doctor / room', flex: 14),
                  GridColumn('Payment', flex: 9),
                  GridColumn('Status', flex: 15),
                  GridColumn('', flex: 3),
                ],
                empty: const EmptyState(
                  title: 'No appointments found',
                  message: 'Try changing your search or filter criteria.',
                ),
                rows: [
                  for (final a in rows)
                    GridRowData(
                      onTap: () => AppointmentDrawer.show(context, a.id),
                      cells: [
                        TwoLine(a.id, a.service),
                        PersonCell(
                          initials: a.initials,
                          title: a.patient,
                          subtitle: a.source,
                        ),
                        TwoLine(a.time, a.date),
                        TwoLine(a.doctor, a.room),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(a.payment),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(a.status),
                        ),
                        Icon(AppIcons.more, size: 18, color: context.c.muted),
                      ],
                    ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.c.borderSoft)),
                ),
                child: Pagination(
                  summary:
                      'Showing 1–${rows.length} of ${data.totalAppointments} appointments',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.tiles});
  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, bc) {
          final n = cols(bc.maxWidth, wide: 5, mid: 3, narrow: 2);
          final itemW = bc.maxWidth / n;
          return Wrap(
            children: [
              for (var i = 0; i < tiles.length; i++)
                SizedBox(
                  width: itemW,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: (i + 1) % n == 0
                              ? Colors.transparent
                              : context.c.border,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: context.c.fg(tiles[i].tone),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              tiles[i].value,
                              style: context.sH1.copyWith(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(tiles[i].label, style: context.sSmall),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
