import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/data_grid.dart';

String money(double v) => '\$${v.toStringAsFixed(2)}';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  static const _tabs = [
    'Invoices',
    'Transactions',
    'Refund requests',
    'Outstanding',
  ];
  String _tab = 'Invoices';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Billing & payments',
          desc:
              'Monitor invoices, verified transactions, refunds, and facility revenue.',
          actions: [
            AppButton('Export ledger', icon: AppIcons.download),
            AppButton(
              'Create invoice',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        _Hero(f: data.finance),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              TabsBar(
                tabs: _tabs,
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              DataGrid(
                minWidth: 900,
                columns: const [
                  GridColumn('Invoice', flex: 10),
                  GridColumn('Patient', flex: 13),
                  GridColumn('Service', flex: 14),
                  GridColumn('Amount', flex: 8),
                  GridColumn('Payment method', flex: 12),
                  GridColumn('Status', flex: 10),
                ],
                rows: [
                  for (final i in data.invoices)
                    GridRowData(
                      cells: [
                        TwoLine(i.id, i.date),
                        TwoLine(i.patient, i.appointmentId),
                        CellText(i.service),
                        Text(money(i.amount), style: context.sStrong),
                        CellText(i.method),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(i.status),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const NoticeBanner(
          title: 'Trusted payment verification enforced',
          message:
              'Online payments can only transition to Paid through verified payment-provider callbacks. Manual success actions are unavailable.',
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.f});
  final FinanceSummary f;

  @override
  Widget build(BuildContext context) {
    final accent = ClinicColors.lighten(context.c.accent, .12);

    Widget stat(String value, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: context.sH2.copyWith(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.sSmall.copyWith(color: const Color(0xFF9FB3C6)),
            ),
          ],
        );

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NET REVENUE · JUNE 2025',
          style: context.sLabel.copyWith(
            color: const Color(0xFF9FB3C6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          f.netRevenue,
          style: context.sH1.copyWith(color: Colors.white, fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          f.growth,
          style: context.sSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final chart = SizedBox(
      height: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < f.spark.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: FractionallySizedBox(
                heightFactor: f.spark[i] / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: .35 + .65 * (i / f.spark.length),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
      decoration: BoxDecoration(
        color: context.c.hero,
        borderRadius: BorderRadius.circular(context.m.radius),
      ),
      child: LayoutBuilder(
        builder: (context, bc) {
          if (bc.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                main,
                const SizedBox(height: 16),
                Wrap(
                  spacing: 28,
                  runSpacing: 12,
                  children: [
                    stat(f.today, 'Revenue today'),
                    stat(f.outstanding, 'Outstanding'),
                    stat(f.refunded, 'Refunded'),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 12, child: main),
              const SizedBox(width: 22),
              Expanded(flex: 15, child: chart),
              const SizedBox(width: 22),
              Expanded(flex: 7, child: stat(f.today, 'Revenue today')),
              Expanded(flex: 7, child: stat(f.outstanding, 'Outstanding')),
              Expanded(flex: 7, child: stat(f.refunded, 'Refunded')),
            ],
          );
        },
      ),
    );
  }
}
