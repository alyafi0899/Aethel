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
import '../widgets/forms.dart';
import '../widgets/toast.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  int _selected = 0;
  String _tab = 'Operational overview';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    final doctors = data.doctors;
    final d = doctors[_selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Doctors',
          desc: 'Manage affiliations, credentials, schedules, and operational availability.',
          actions: [
            AppButton('Notify doctors', icon: AppIcons.send),
            AppButton(
              'Add affiliation',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        FilterBar(
          dateLabel: data.todayShort,
          children: const [
            FilterPill('All specialties'),
            FilterPill('All statuses'),
          ],
        ),
        LayoutBuilder(
          builder: (context, bc) {
            final list = _DoctorList(
              doctors: doctors,
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
            );
            final detail = _DoctorDetail(
              doctor: d,
              tab: _tab,
              onTab: (t) => setState(() => _tab = t),
              schedule: data.appointments.take(3).toList(),
            );
            if (bc.maxWidth < 900) {
              return Column(
                children: [list, const SizedBox(height: 12), detail],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 290, child: list),
                const SizedBox(width: 12),
                Expanded(child: detail),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DoctorList extends StatelessWidget {
  const _DoctorList({
    required this.doctors,
    required this.selected,
    required this.onSelect,
  });
  final List<Doctor> doctors;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: SearchBox(hint: 'Search doctors', filled: false),
          ),
          for (var i = 0; i < doctors.length; i++)
            Material(
              color: i == selected
                  ? context.c.soft(Tone.blue)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.c.borderSoft),
                    ),
                  ),
                  child: Row(
                    children: [
                      Avatar(
                        doctors[i].initials,
                        tone: doctors[i].tone,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctors[i].name, style: context.sStrong),
                            const SizedBox(height: 2),
                            Text(
                              '${doctors[i].specialty} · ${doctors[i].registration}',
                              style: context.sSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            StatusBadge(doctors[i].status),
                          ],
                        ),
                      ),
                      Icon(AppIcons.chevron, size: 14, color: context.c.muted),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DoctorDetail extends StatelessWidget {
  const _DoctorDetail({
    required this.doctor,
    required this.tab,
    required this.onTab,
    required this.schedule,
  });

  final Doctor doctor;
  final String tab;
  final ValueChanged<String> onTab;
  final List<Appointment> schedule;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final times = ['09:00', '10:15', '14:00'];
    final badges = ['Completed', 'Confirmed', 'Pending'];

    Widget metric(
      String label,
      String value,
      String sub, {
      bool last = false,
    }) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: last ? Colors.transparent : c.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.sLabel),
            const SizedBox(height: 5),
            Text(value, style: context.sH2),
            const SizedBox(height: 2),
            Text(sub, style: context.sSmall),
          ],
        ),
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 84,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.soft(Tone.blue), c.soft(Tone.teal)],
              ),
            ),
            child: const AppIconButton(AppIcons.more),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Avatar(doctor.initials, tone: doctor.tone, size: 62),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            doctor.name,
                            style: context.sH1.copyWith(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.check,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${doctor.specialty} · Senior Consultant',
                        style: context.sSmall,
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(doctor.status),
                    ],
                  ),
                  AppButton(
                    'Notify',
                    icon: AppIcons.bell,
                    onPressed: () => Toast.show(
                      context,
                      'Operational update sent to ${doctor.name}.',
                    ),
                  ),
                  const AppButton(
                    'View schedule',
                    icon: AppIcons.calendar,
                    kind: BtnKind.primary,
                  ),
                ],
              ),
            ),
          ),
          TabsBar(
            tabs: const [
              'Operational overview',
              'Affiliation',
              'Credentials',
              'Preferences',
            ],
            selected: tab,
            onChanged: onTab,
          ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(context.m.radiusSm),
            ),
            child: LayoutBuilder(
              builder: (context, bc) {
                final cards = [
                  metric(
                    "TODAY'S SCHEDULE",
                    '${doctor.todayCount}',
                    '2 remaining',
                  ),
                  metric('COMPLETED', '6', 'Today'),
                  metric('PENDING REQUESTS', '3', 'Needs response'),
                  metric(
                    'WORKING HOURS',
                    '08:00–17:00',
                    'Break 12:30–13:15',
                    last: true,
                  ),
                ];
                if (bc.maxWidth < 520) {
                  return Column(
                    children: [
                      Row(children: [cards[0], cards[1]]),
                      Row(children: [cards[2], cards[3]]),
                    ],
                  );
                }
                return Row(children: cards);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('Today’s schedule', style: context.sH3),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < schedule.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: Text(times[i], style: context.sStrong),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: i == 0 ? c.fg(Tone.green) : c.surface,
                      border: Border.all(
                        color: i == 0 ? c.fg(Tone.green) : c.border,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedule[i].patient, style: context.sStrong),
                        Text(
                          '${schedule[i].service} · ${schedule[i].room}',
                          style: context.sSmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(badges[i]),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: NoticeBanner(
              icon: AppIcons.lock,
              tone: Tone.gray,
              title: 'Clinical privacy enforced',
              message: 'Administrative access does not include confidential consultation notes or conversations.',
            ),
          ),
        ],
      ),
    );
  }
}
