import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Consultation operations',
          desc:
              'Operational visibility for in-person and online sessions without exposing private clinical content.',
          actions: [AppButton('Filter queue', icon: AppIcons.filter)],
        ),
        AdaptiveGrid(
          columns: (w) => cols(w, wide: 4, mid: 2, narrow: 2),
          children: [for (final s in data.consultStats) StatCard(s)],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: DataGrid(
            minWidth: 900,
            columns: const [
              GridColumn('Consultation', flex: 12),
              GridColumn('Patient', flex: 11),
              GridColumn('Doctor', flex: 12),
              GridColumn('Type', flex: 11),
              GridColumn('Start time', flex: 9),
              GridColumn('Status', flex: 12),
            ],
            rows: [
              for (final c in data.consultations)
                GridRowData(
                  cells: [
                    TwoLine(c.id, c.appointmentId),
                    CellText(c.patient),
                    CellText(c.doctor),
                    CellText(c.type),
                    CellText(c.startTime),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(c.status),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const NoticeBanner(
          icon: AppIcons.lock,
          title: 'Content privacy boundary',
          message:
              'Clinic operations staff can see session status and routing metadata, but not confidential messages or clinical notes.',
        ),
      ],
    );
  }
}
