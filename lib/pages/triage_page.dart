import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../sheets/clinical_review_panel.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';
import '../widgets/forms.dart';

class TriagePage extends StatefulWidget {
  const TriagePage({super.key});

  @override
  State<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends State<TriagePage> {
  static const _tabs = ['New Screening', 'In Review', 'Escalated', 'Completed'];
  static const _priorities = [
    'All priorities',
    'Urgent',
    'Priority',
    'Routine',
    'Unassigned',
  ];

  String _tab = _tabs.first;
  String _query = '';
  String _priority = _priorities.first;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    final q = _query.toLowerCase();
    final visible = data.screenings
        .where((s) => s.status == _tab)
        .where(
          (s) => (s.patient + s.appointment + s.complaint)
              .toLowerCase()
              .contains(q),
        )
        .where((s) => _priority == 'All priorities' || s.priority == _priority)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Triage & screening',
          desc: 'Review pre-consultation intake, identify red flags, and route patients to authorized clinical personnel.',
          actions: [
            AppButton('Export queue', icon: AppIcons.download),
            AppButton(
              'New screening',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        const NoticeBanner(
          title: 'Clinical safety boundary',
          message: 'Screening supports structured review; it does not diagnose. Red-flag symptoms must be escalated to authorized clinical personnel and kept out of routine queues.',
          actionLabel: 'View escalation protocol',
        ),
        const SizedBox(height: 12),
        AdaptiveGrid(
          columns: (w) => cols(w, wide: 5, mid: 3, narrow: 2),
          children: [for (final t in data.triageStats) StatCard(t)],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabsBar(
                tabs: _tabs,
                selected: _tab,
                counts: const {'Escalated': '3'},
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
                      width: 300,
                      child: SearchBox(
                        hint: 'Search patient, appointment, or complaint',
                        filled: false,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const FilterPill('Submitted today'),
                    SizedBox(
                      width: 160,
                      child: AppDropdown(
                        items: _priorities,
                        value: _priority,
                        onChanged: (v) =>
                            setState(() => _priority = v ?? _priorities.first),
                      ),
                    ),
                    const FilterPill(
                      'Advanced filters',
                      icon: AppIcons.filter,
                      chevron: false,
                      count: '1',
                    ),
                  ],
                ),
              ),
              DataGrid(
                minWidth: 1080,
                columns: const [
                  GridColumn('Patient / appointment', flex: 16),
                  GridColumn('Main complaint', flex: 15),
                  GridColumn('Duration', flex: 9),
                  GridColumn('Screening', flex: 10),
                  GridColumn('Priority', flex: 9),
                  GridColumn('Clinical reviewer', flex: 12),
                  GridColumn('Submitted', flex: 9),
                  GridColumn('', flex: 3),
                ],
                empty: EmptyState(
                  icon: AppIcons.check,
                  title: 'No records in $_tab',
                  message: 'There are no screening records matching the current filters.',
                ),
                rows: [
                  for (final s in visible)
                    GridRowData(
                      highlight: s.redFlag
                          ? context.c.soft(Tone.red).withValues(alpha: .5)
                          : null,
                      onTap: () => ClinicalReviewPanel.show(context, s),
                      cells: [
                        PersonCell(
                          initials: s.initials,
                          title: s.patient,
                          subtitle: '${s.appointment} · ${s.id}',
                        ),
                        TwoLine(s.complaint, s.source),
                        CellText(s.duration),
                        _Completion(s.completion),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusBadge(s.priority),
                            if (s.redFlag)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.alert,
                                      size: 11,
                                      color: context.c.fg(Tone.red),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Red flag',
                                      style: context.sSmall.copyWith(
                                        color: context.c.fg(Tone.red),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        TwoLine(
                          s.reviewer,
                          s.reviewer == 'Unassigned'
                              ? 'Assign reviewer'
                              : 'Clinical team',
                        ),
                        TwoLine(s.submitted, 'Jun 17, 2025'),
                        Icon(
                          AppIcons.chevron,
                          size: 18,
                          color: context.c.muted,
                        ),
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
                      'Showing ${visible.length} of ${data.screenings.length} screening records',
                  pages: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Completion extends StatelessWidget {
  const _Completion(this.value);
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 5,
              backgroundColor: context.c.border,
              color: value >= 100
                  ? context.c.fg(Tone.green)
                  : context.c.primary,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text('$value%', style: context.sStrong.copyWith(fontSize: 11)),
      ],
    );
  }
}
