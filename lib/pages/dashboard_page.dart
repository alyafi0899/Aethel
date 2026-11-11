import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/responsive.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../sheets/appointment_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final data = ctrl.data;
    final firstName = data.userName.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: data.todayLabel,
          title: 'Good morning, $firstName',
          desc: 'Here’s what’s happening across ${data.facilityName} today.',
          actions: [
            const AppButton('Export report', icon: AppIcons.download),
            AppButton(
              'New appointment',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
              onPressed: () => ctrl.go(AppPage.appointments),
            ),
          ],
        ),
        FilterBar(
          dateLabel: data.todayShort,
          children: const [
            FilterPill('All departments'),
            FilterPill('All doctors'),
          ],
        ),
        AdaptiveGrid(
          spacing: 10,
          columns: (w) => cols(w, wide: 6, mid: 3, narrow: 2),
          children: [for (final m in data.metrics) _MetricCard(m)],
        ),
        const SizedBox(height: 12),
        SplitLayout(
          stretch: true,
          gap: 12,
          leftFlex: 155,
          rightFlex: 100,
          left: _TimelineCard(appointments: ctrl.appointments),
          right: _AvailabilityCard(a: data.availability),
        ),
        const SizedBox(height: 12),
        SplitLayout(
          stretch: true,
          gap: 12,
          leftFlex: 155,
          rightFlex: 100,
          left: _RoomsCard(stats: data.roomStats),
          right: _ActivityCard(items: data.activity),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.m);
  final Metric m;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.read<AppController>().go(m.target),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(m.icon, tone: m.tone),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  m.label,
                  style: context.sSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(AppIcons.chevron, size: 13, color: context.c.muted),
            ],
          ),
          const SizedBox(height: 4),
          Text(m.value, style: context.sH1.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            m.sub,
            style: context.sSmall.copyWith(
              color: m.sub.contains('+')
                  ? context.c.fg(Tone.green)
                  : context.c.muted,
              fontWeight:
                  m.sub.contains('+') ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.appointments});
  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<AppController>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 12),
            child: CardHead(
              title: 'Today’s appointment timeline',
              subtitle: '32 appointments across 8 departments',
              trailing: LinkButton(
                'View calendar',
                onTap: () => ctrl.go(AppPage.appointments),
              ),
            ),
          ),
          Builder(
            builder: (context) {
              // NOTE: no LayoutBuilder here - this card sits inside an
              // IntrinsicHeight (equal-height row), which cannot measure one.
              final vw = MediaQuery.sizeOf(context).width;
              final contentWidth = vw >= 850 ? vw - 314 : vw - 26;
              final narrow = contentWidth < 580;
              return Column(
                children: [
                  if (!narrow)
                    Container(
                      height: 30,
                      color: context.c.surfaceAlt,
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text('TIME', style: context.sLabel),
                          ),
                          Expanded(
                            flex: 15,
                            child: Text('APPOINTMENT', style: context.sLabel),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text('DOCTOR & ROOM', style: context.sLabel),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text('STATUS', style: context.sLabel),
                          ),
                        ],
                      ),
                    ),
                  for (var i = 0; i < appointments.take(4).length; i++)
                    _TimelineRow(a: appointments[i], index: i, narrow: narrow),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.a,
    required this.index,
    required this.narrow,
  });
  final Appointment a;
  final int index;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final caption = index == 0 ? 'Now' : (index == 1 ? 'In 30 min' : '');
    final time = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.time, style: context.sStrong),
        if (caption.isNotEmpty)
          Text(
            caption,
            style: context.sSmall.copyWith(
              color: context.c.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
    final person = Row(
      children: [
        Avatar(a.initials),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.patient,
                style: context.sStrong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                a.service,
                style: context.sSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    final doctor = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a.doctor,
          style: context.sStrong,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(a.room, style: context.sSmall),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AppointmentDrawer.show(context, a.id),
        child: Container(
          constraints: BoxConstraints(minHeight: context.m.rowHeight),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.c.borderSoft)),
          ),
          child: narrow
              ? Row(
                  children: [
                    SizedBox(width: 70, child: time),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          person,
                          const SizedBox(height: 6),
                          StatusBadge(a.status),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 90, child: time),
                    Expanded(flex: 15, child: person),
                    const SizedBox(width: 10),
                    Expanded(flex: 12, child: doctor),
                    SizedBox(
                      width: 130,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(a.status),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.a});
  final DoctorAvailability a;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget legend(Color color, String label, int n) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: context.sBody)),
              Text('$n', style: context.sStrong),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHead(
            title: 'Doctor availability',
            subtitle: 'Live operational status',
            trailing: AppIconButton(AppIcons.more),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(108, 108),
                      painter: _DonutPainter([
                        (a.available.toDouble(), c.fg(Tone.green)),
                        (a.consulting.toDouble(), c.primary),
                        (a.onBreak.toDouble(), c.fg(Tone.amber)),
                        (a.unavailable.toDouble(), c.border),
                      ], stroke: 16),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${a.rostered}',
                          style: context.sH1.copyWith(fontSize: 24),
                        ),
                        Text('Rostered', style: context.sSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    legend(c.fg(Tone.green), 'Available', a.available),
                    legend(c.primary, 'Consulting', a.consulting),
                    legend(c.fg(Tone.amber), 'On break', a.onBreak),
                    legend(c.border, 'Unavailable', a.unavailable),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.read<AppController>().go(AppPage.doctors),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(context.m.radiusSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage doctor schedules',
                      style: context.sStrong.copyWith(color: c.primary),
                    ),
                  ),
                  Icon(AppIcons.arrow, size: 15, color: c.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, {required this.stroke});

  final List<(double, Color)> segments;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (s, e) => s + e.$1);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = 2 * math.pi * seg.$1 / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = seg.$2;
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.stroke != stroke;
}

class _RoomsCard extends StatelessWidget {
  const _RoomsCard({required this.stats});
  final List<StatTile> stats;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 0),
            child: CardHead(
              title: 'Rooms & resources',
              subtitle: 'Current allocation status',
              trailing: LinkButton(
                'View all',
                arrow: false,
                onTap: () => context.read<AppController>().go(AppPage.rooms),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Row(
              children: [
                for (final s in stats)
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.soft(s.tone),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 17, color: c.fg(s.tone)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.value,
                          style: context.sH1.copyWith(fontSize: 22),
                        ),
                        Text(s.label, style: context.sSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.soft(Tone.amber),
              border: Border.all(color: c.fg(Tone.amber).withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            ),
            child: Row(
              children: [
                Icon(AppIcons.alert, size: 16, color: c.fg(Tone.amber)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room R-104 unavailable',
                        style: context.sStrong.copyWith(
                          color: c.fg(Tone.amber),
                        ),
                      ),
                      Text(
                        '2 appointments may need reallocation',
                        style: context.sSmall.copyWith(
                          color: c.fg(Tone.amber).withValues(alpha: .85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevron, size: 14, color: c.fg(Tone.amber)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.items});
  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 10),
            child: CardHead(
              title: 'Live activity',
              subtitle: 'Real-time facility events',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.soft(Tone.green),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.fg(Tone.green),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: context.sLabel.copyWith(
                        color: c.fg(Tone.green),
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final i in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.borderSoft)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.soft(Tone.blue),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(i.icon, size: 15, color: c.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.title, style: context.sStrong),
                        Text(
                          i.subtitle,
                          style: context.sSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(i.time, style: context.sSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
