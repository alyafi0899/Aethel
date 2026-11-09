import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/theme/clinic_colors.dart';
import '../core/theme/context_ext.dart';
import '../state/app_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/forms.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  static const _actions = ['View', 'Create', 'Edit', 'Delete'];
  int _role = 1;
  late final List<List<bool>> _matrix;

  @override
  void initState() {
    super.initState();
    final names = context.read<AppController>().data.permissionNames;
    _matrix = [
      for (var i = 0; i < names.length; i++)
        [
          for (var j = 0; j < _actions.length; j++)
            i != 2 && !(j == 3 && i > 3),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().data;
    final c = context.c;
    final role = data.roles[_role];

    final list = AppCard(
      child: Column(
        children: [
          for (var i = 0; i < data.roles.length; i++)
            Material(
              color: i == _role ? c.soft(Tone.blue) : Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _role = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: i == 0 ? Colors.transparent : c.borderSoft,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconBox(
                        data.roles[i].icon,
                        tone: i == _role ? Tone.blue : Tone.gray,
                        size: 32,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.roles[i].name, style: context.sStrong),
                            Text(
                              '${data.roles[i].members} active members',
                              style: context.sSmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(AppIcons.chevron, size: 14, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final matrix = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 12),
            child: CardHead(
              title: role.name,
              subtitle:
              'Operational administration without confidential clinical access',
              trailing: const AppButton(
                'Edit role',
                icon: AppIcons.edit,
                compact: true,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 520),
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    for (var i = 0; i < data.permissionNames.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.border)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 190,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.permissionNames[i],
                                    style: context.sStrong,
                                  ),
                                  Text(
                                    i == 2
                                        ? 'Only explicitly authorized summaries'
                                        : 'Facility-scoped operational access',
                                    style: context.sSmall,
                                  ),
                                ],
                              ),
                            ),
                            for (var j = 0; j < _actions.length; j++)
                              SizedBox(
                                width: 78,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _matrix[i][j],
                                        onChanged: (v) => setState(
                                              () => _matrix[i][j] = v ?? false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(_actions[j], style: context.sSmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(
          title: 'Roles & permissions',
          desc:
          'Configure facility access boundaries. Backend row-level policies remain authoritative.',
          actions: [
            AppButton(
              'Create custom role',
              icon: AppIcons.plus,
              kind: BtnKind.primary,
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, bc) {
            if (bc.maxWidth < 900) {
              return Column(
                children: [list, const SizedBox(height: 12), matrix],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: list),
                const SizedBox(width: 12),
                Expanded(child: matrix),
              ],
            );
          },
        ),
        const NoticeBanner(
          title: 'Defense in depth',
          message:
          'Hidden UI actions improve usability, but authorization must be enforced through Supabase RLS, RPC permission checks, and audited Edge Functions.',
        ),
      ],
    );
  }
}