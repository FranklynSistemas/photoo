import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/providers/location_provider.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/settings/app_state.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Run the app
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => AppState()), // Provide AppState globally
      ChangeNotifierProvider(
        create: (_) =>
            LocationProvider()..fetchLocation(), // Fetch location on app start
      ),
    ],
    child: MyApp(
        settingsController: settingsController, navigatorKey: navigatorKey),
  ));
}
