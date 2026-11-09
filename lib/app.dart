import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'shell/app_shell.dart';

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ThemeController>().config;
    return MaterialApp(
      title: 'Prometheon Clinic OS',
      debugShowCheckedModeBanner: false,
      themeMode: cfg.mode,
      theme: AppTheme.build(cfg, Brightness.light),
      darkTheme: AppTheme.build(cfg, Brightness.dark),
      home: const AppShell(),
    );
  }
}
