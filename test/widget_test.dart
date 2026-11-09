import 'package:clinic_operations_platform/app.dart';
import 'package:clinic_operations_platform/core/theme/theme_config.dart';
import 'package:clinic_operations_platform/core/theme/theme_controller.dart';
import 'package:clinic_operations_platform/data/clinic_repository.dart';
import 'package:clinic_operations_platform/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('dashboard renders with mock data', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeController(
              kInitialThemeConfig.copyWith(useGoogleFonts: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AppController(const MockClinicRepository()),
          ),
        ],
        child: const ClinicApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Good morning, Elena'), findsOneWidget);
    expect(find.text('PROMETHEON'), findsOneWidget);
  });
}
