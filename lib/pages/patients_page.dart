import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    final q = _query.toLowerCase();
    final rows = data.patients
        .where((p) => (p.name + p.globalId + p.mrn).toLowerCase().contains(q))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Patient directory',
          desc: 'Global patient identities with facility-scoped registration and record access.',
          actions: [
            AppButton(
              'Register patient',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        const NoticeBanner(
          title: 'Facility-scoped clinical access',
          message: 'Records from other facilities remain restricted unless explicit authorization is present.',
          actionLabel: 'Review access policy',
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 320,
                      child: SearchBox(
                        hint: 'Search name, global ID, or local MRN',
                        filled: false,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const FilterPill('Registration status'),
                  ],
                ),
              ),
              DataGrid(
                minWidth: 900,
                columns: const [
                  GridColumn('Patient', flex: 14),
                  GridColumn('Global patient ID', flex: 11),
                  GridColumn('Local MRN', flex: 12),
                  GridColumn('Registration', flex: 10),
                  GridColumn('Last visit', flex: 10),
                  GridColumn('Record access', flex: 14),
                ],
                empty: const EmptyState(
                  title: 'No patients found',
                  message: 'Try a different name, global ID, or MRN.',
                ),
                rows: [
                  for (final p in rows)
                    GridRowData(
                      cells: [
                        PersonCell(initials: p.initials, title: p.name),
                        CellText(p.globalId),
                        Text(p.mrn, style: context.sStrong),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(p.registration),
                        ),
                        CellText(p.lastVisit),
                        Row(
                          children: [
                            Icon(
                              AppIcons.lock,
                              size: 14,
                              color: context.c.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Authorized summary only',
                                style: context.sBody,
                              ),
                            ),
                          ],
                        ),
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
