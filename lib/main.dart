import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/theme/theme_controller.dart';
import 'data/supabase_clinic_repository.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/clinic/state/clinic_controller.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: EnvConfig.supabasePublishableKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => AppController(SupabaseClinicRepository()),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ClinicController()),
      ],
      child: const ClinicApp(),
    ),
  );
}
