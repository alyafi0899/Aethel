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
import '../widgets/toast.dart';

Tone _roomTone(String status) {
  switch (status) {
    case 'Available':
      return Tone.green;
    case 'Occupied':
      return Tone.blue;
    case 'Reserved':
      return Tone.amber;
    case 'Maintenance':
      return Tone.red;
  }
  return Tone.gray;
}

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  String _chosen = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Rooms & resources',
          desc: 'Monitor capacity, resolve conflicts, and coordinate healthcare resource allocation.',
          actions: [
            AppButton('Manage maintenance', icon: AppIcons.settings),
            AppButton(
              'Add resource',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        AdaptiveGrid(
          spacing: 10,
          columns: (w) => cols(w, wide: 5, mid: 3, narrow: 2),
          children: [for (final t in data.resourceStats) StatCard(t)],
        ),
        const SizedBox(height: 12),
        SplitLayout(
          leftFlex: 15,
          rightFlex: 10,
          gap: 12,
          left: _FloorCard(
            rooms: data.rooms,
            chosen: _chosen,
            onChoose: (c) => setState(() => _chosen = c),
          ),
          right: const _ConflictCard(),
        ),
      ],
    );
  }
}

class _FloorCard extends StatelessWidget {
  const _FloorCard({
    required this.rooms,
    required this.chosen,
    required this.onChoose,
  });
  final List<RoomItem> rooms;
  final String chosen;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    Widget tile(RoomItem r) {
      final tone = _roomTone(r.status);
      final selected = chosen == r.code;
      return Expanded(
        child: InkWell(
          onTap: () => onChoose(r.code),
          child: Container(
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.soft(tone),
              border: Border.all(
                color: selected ? c.primary : c.fg(tone).withValues(alpha: .35),
                width: selected ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  r.code.contains('LAB') ? AppIcons.service : AppIcons.room,
                  size: 20,
                  color: c.fg(tone),
                ),
                const SizedBox(height: 5),
                Text(
                  r.code,
                  style: context.sStrong.copyWith(color: c.fg(tone)),
                ),
                Text(
                  r.type,
                  textAlign: TextAlign.center,
                  style: context.sSmall.copyWith(
                    color: c.fg(tone).withValues(alpha: .85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.status,
                  style: context.sLabel.copyWith(
                    color: c.fg(tone),
                    letterSpacing: .2,
                  ),
                ),
                Text(
                  r.note,
                  style: context.sSmall.copyWith(fontSize: 9.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget rowOf(List<RoomItem> items) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          tile(items[i]),
        ],
      ],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(17, 16, 17, 0),
            child: CardHead(
              title: '2nd floor · Clinical wing',
              subtitle: 'Live room occupancy',
              trailing: FilterPill('2nd floor'),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              border: Border.all(color: c.border, width: 8),
            ),
            child: Column(
              children: [
                IntrinsicHeight(child: rowOf(rooms.take(3).toList())),
                const SizedBox(height: 8),
                Container(
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: c.borderSoft,
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        'CLINICAL CORRIDOR',
                        style: context.sLabel.copyWith(
                          letterSpacing: 2,
                          fontSize: 8.5,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Reception →',
                            style: context.sSmall.copyWith(fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IntrinsicHeight(child: rowOf(rooms.skip(3).take(3).toList())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    Widget conflict({
      required Tone tone,
      required IconData icon,
      required String title,
      required String body,
      required String detected,
      required String action,
      required String toast,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.borderSoft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.soft(tone),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: c.fg(tone)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.sStrong),
                  const SizedBox(height: 3),
                  Text(body, style: context.sBody),
                  const SizedBox(height: 3),
                  Text(detected, style: context.sSmall),
                  const SizedBox(height: 6),
                  LinkButton(action, onTap: () => Toast.show(context, toast)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 12),
            child: CardHead(
              title: 'Allocation conflicts',
              subtitle: 'Requires operational action',
              trailing: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.soft(Tone.red),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '2',
                  style: context.sLabel.copyWith(
                    color: c.fg(Tone.red),
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
          conflict(
            tone: Tone.red,
            icon: AppIcons.alert,
            title: 'Room R-104 unavailable',
            body: 'Maintenance overlaps with 2 radiology bookings tomorrow.',
            detected: 'Detected 12 minutes ago',
            action: 'Start reallocation',
            toast: 'Reallocation workflow started for 2 affected appointments.',
          ),
          conflict(
            tone: Tone.amber,
            icon: AppIcons.clock,
            title: 'Equipment overlap',
            body: 'Ultrasound unit US-02 requested for two services at 14:30.',
            detected: 'Detected 28 minutes ago',
            action: 'Resolve conflict',
            toast: 'Conflict details opened. Alternative equipment identified.',
          ),
        ],
      ),
    );
  }
}
