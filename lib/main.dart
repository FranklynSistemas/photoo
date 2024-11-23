import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/settings/folder_state.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void printHello() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=$isolateId function='$printHello'");
}

@pragma('vm:entry-point')
void activateApp() async {
  print("App activated at 9:00 AM: ${DateTime.now()}");
  WakelockPlus.enable(); // Keep the screen active

  // Schedule the next activation for the following day at 9 a.m.
  //await scheduleActivateAlarm();
}

@pragma('vm:entry-point')
void deactivateApp() async {
  print("App allowed to sleep at 11:00 PM: ${DateTime.now()}");
  WakelockPlus.disable(); // Allow the screen to go to sleep
  bool wakelockEnabled = await WakelockPlus.enabled;
  print("wakelockEnabled: $wakelockEnabled");

  // Schedule the next deactivation for the following day at 11 p.m.
  await scheduleDeactivateAlarm();
}

// Scheduling the daily activation alarm
Future<void> scheduleActivateAlarm() async {
  final DateTime now = DateTime.now();
  final DateTime activationTime =
      DateTime(now.year, now.month, now.day, now.hour, now.minute + 2);

  await AndroidAlarmManager.oneShotAt(
    activationTime.isBefore(now)
        ? activationTime.add(const Duration(
            days: 1)) // If 9 a.m. has passed, schedule for the next day
        : activationTime,
    1, // Unique ID for the activation alarm
    activateApp,
    exact: true,
    wakeup: true,
  );
  print(
      "Activation alarm scheduled for: $activationTime, is before now ${activationTime.isBefore(now)}");
}

// Scheduling the daily deactivation alarm
Future<void> scheduleDeactivateAlarm() async {
  final DateTime now = DateTime.now();
  final DateTime deactivationTime =
      DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);

  await AndroidAlarmManager.oneShotAt(
    deactivationTime.isBefore(now)
        ? deactivationTime.add(const Duration(
            days: 1)) // If 11 p.m. has passed, schedule for the next day
        : deactivationTime,
    2, // Unique ID for the deactivation alarm
    deactivateApp,
    exact: true,
    wakeup: true,
  );
  print("Deactivation alarm scheduled for $deactivationTime");
}

// Cancel all alarms
Future<void> cancelAlarms() async {
  await AndroidAlarmManager.cancel(1); // Cancel the activation alarm
  await AndroidAlarmManager.cancel(2); // Cancel the deactivation alarm
  WakelockPlus.disable(); // Ensure wakelock is disabled
  print("All alarms canceled and wakelock disabled");
}

Future<bool> _needsExactAlarmPermission() async {
  if (Platform.isAndroid && (await Permission.scheduleExactAlarm.isDenied)) {
    return true;
  }
  return false;
}

// Request exact alarm permission by redirecting to app settings
void _requestExactAlarmPermission() {
  print("Current context: ${navigatorKey.currentContext}");
  if (navigatorKey.currentContext != null) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Exact Alarm Permission Required"),
          content: const Text(
              "This app requires permission to schedule exact alarms for timed functionality. Please enable it in app settings."),
          actions: <Widget>[
            TextButton(
              child: const Text("Go to Settings"),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // After user returns from settings, check permission again
                if (await Permission.scheduleExactAlarm.isGranted) {
                  activateApp();
                  await scheduleDeactivateAlarm();
                } else {
                  print("Exact Alarm permission not granted.");
                }
              },
            ),
          ],
        );
      },
    );
  } else {
    print("Context is still null, dialog could not be shown.");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Run the app
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => FolderState()), // Provide FolderState globally
    ],
    child: MyApp(
        settingsController: settingsController, navigatorKey: navigatorKey),
  ));
  // Check and request permission only after the app has built
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (Platform.isAndroid && await _needsExactAlarmPermission()) {
      _requestExactAlarmPermission();
    } else {
      // Initialize daily activation and deactivation alarms
      activateApp();
      await scheduleDeactivateAlarm();
    }
  });
  // Listen for app lifecycle changes to cancel alarms when the app closes
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      print('Cancelling the alarms');
      cancelAlarms(); // Cancel alarms when app is closed or goes inactive
    }
    super.didChangeAppLifecycleState(state);
  }
}
