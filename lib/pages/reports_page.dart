import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Reports & analytics',
          desc:
              'Operational performance across appointments, resources, services, and communications.',
          actions: [
            AppButton('CSV', icon: AppIcons.download),
            AppButton(
              'PDF report',
              icon: AppIcons.download,
              kind: BtnKind.primary,
            ),
          ],
        ),
        const FilterBar(
          dateLabel: 'June 1–17, 2025',
          children: [FilterPill('All departments'), FilterPill('All services')],
        ),
        SplitLayout(
          leftFlex: 15,
          rightFlex: 10,
          gap: 12,
          left: _ChartCard(bars: data.weekly),
          right: _KpiCard(kpis: data.kpis),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.bars});
  final List<WeeklyBar> bars;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const plotH = 200.0;
    const axis = ['120', '90', '60', '30', '0'];

    Widget bar(double pct, Color color, double h) => Container(
          width: 9,
          height: h * pct / 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        );

    Widget legend(Color color, String label) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: context.sSmall),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHead(
            title: 'Appointment performance',
            subtitle: 'Completed, cancelled, and no-show volume',
            trailing: StatusBadge('+8.2% growth'),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 34,
                height: plotH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in axis) Text(a, style: context.sSmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: plotH,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainter(c.borderSoft, axis.length),
                            ),
                          ),
                          Row(
                            children: [
                              for (final b in bars)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        bar(b.completed, c.primary, plotH),
                                        const SizedBox(width: 3),
                                        bar(b.cancelled, c.accent, plotH),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final b in bars)
                          Expanded(
                            child: Center(
                              child: Text(b.day, style: context.sSmall),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              legend(c.primary, 'Completed'),
              legend(c.accent, 'Cancelled / no-show'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color, this.lines);
  final Color color;
  final int lines;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < lines; i++) {
      final y = i * (size.height - 1) / (lines - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.color != color || old.lines != lines;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpis});
  final List<Kpi> kpis;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(17, 16, 17, 8),
            child: CardHead(
              title: 'Operational indicators',
              subtitle: 'June 1–17, 2025',
            ),
          ),
          for (final k in kpis)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(k.label, style: context.sBody)),
                  Text(k.value, style: context.sStrong),
                  SizedBox(
                    width: 55,
                    child: Text(
                      k.delta,
                      textAlign: TextAlign.right,
                      style: context.sSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _good(k) ? c.fg(Tone.green) : c.fg(Tone.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _good(Kpi k) => k.delta.startsWith('-') ? k.goodWhenNegative : true;
}
