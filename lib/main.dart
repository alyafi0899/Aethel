import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'data/supabase_clinic_repository.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://qshmccjazkupvbelyjhi.supabase.co',
      anonKey: 'sb_publishable_0FJxIsGzTDi8AeIj42utSQ_IPEKBWkZ',
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
      ],
      child: const ClinicApp(),
    ),
  );
}
