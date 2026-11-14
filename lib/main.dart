import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/feature_flags.dart';
import 'core/config/env.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/formatters.dart';
import 'data/supabase_clinic_repository.dart';
import 'data/clinic_repository.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/auth/state/current_staff_controller.dart';
import 'features/clinic/state/clinic_controller.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFormatters.initializeLocaleData();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: EnvConfig.supabasePublishableKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => AppController(
            kUseMockData
                ? const MockClinicRepository()
                : SupabaseClinicRepository(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, CurrentStaffController>(
          create: (_) => CurrentStaffController(),
          update: (_, auth, staff) => staff!..syncMembership(auth.membership),
        ),
        ChangeNotifierProvider(create: (_) => ClinicController()),
      ],
      child: const ClinicApp(),
    ),
  );
}
