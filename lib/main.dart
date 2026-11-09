import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'data/clinic_repository.dart';
import 'state/app_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // Swap MockClinicRepository for your own ClinicRepository to use real data.
        ChangeNotifierProvider(
          create: (_) => AppController(const MockClinicRepository()),
        ),
      ],
      child: const ClinicApp(),
    ),
  );
}
