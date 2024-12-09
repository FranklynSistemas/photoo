import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photoo/src/settings/app_state.dart';
import 'package:provider/provider.dart';

import 'features/photos_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

const platform = MethodChannel('com.example.photoo/screen');

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    required this.settingsController,
    required this.navigatorKey,
  });

  final SettingsController settingsController;
  final GlobalKey<NavigatorState> navigatorKey;

  bool _isScheduleInitialized = false; // Add a flag to track initialization

  // Convert TimeOfDay to milliseconds
  int TimeOfDayToMillis(TimeOfDay time) {
    final now = DateTime.now();
    final scheduleTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return scheduleTime.millisecondsSinceEpoch;
  }

  // Save the schedule using native platform
  Future<void> _saveSchedule(TimeOfDay? onTime, TimeOfDay? offTime) async {
    if (onTime != null && offTime != null) {
      final onTimeInMillis = TimeOfDayToMillis(onTime);
      final offTimeInMillis = TimeOfDayToMillis(offTime);

      try {
        await platform.invokeMethod('scheduleScreenOnOff', {
          'onTime': onTimeInMillis,
          'offTime': offTimeInMillis,
        });
        print('Schedule correctly -> $onTimeInMillis - $offTimeInMillis');
      } catch (e) {
        print('Error setting up schedule -> $e');
      }
    } else {
      print('Select valid times first!');
    }
  }

  Future<bool> _needsExactAlarmPermission() async {
    if (Platform.isAndroid && (await Permission.scheduleExactAlarm.isDenied)) {
      return true;
    }
    return false;
  }

  // Request exact alarm permission by redirecting to app settings
  void _requestExactAlarmPermission(TimeOfDay onTime, TimeOfDay offTime) {
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
                    await _saveSchedule(
                      onTime,
                      offTime,
                    );
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isScheduleInitialized) {
        _isScheduleInitialized = true; // Set the flag to true after first run
        await Future.delayed(const Duration(milliseconds: 100));
        if (Platform.isAndroid && await _needsExactAlarmPermission()) {
          _requestExactAlarmPermission(appState.onTime, appState.offTime);
        } else {
          // Initialize daily activation and deactivation alarms
          platform.invokeMethod('keepScreenOn');
          await _saveSchedule(
            appState.onTime,
            appState.offTime,
          );
        }
      }
    });

    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case PhotosView.routeName:
                  default:
                    return const PhotosView();
                }
              },
            );
          },
        );
      },
    );
  }
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      print('Cancelling the wakeLock');
      platform.invokeMethod('releaseScreenOn');
    }
    super.didChangeAppLifecycleState(state);
  }
}
