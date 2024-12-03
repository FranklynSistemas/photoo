import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'features/photos_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

const platform = MethodChannel('com.example.photoo/screen');

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
    required this.navigatorKey,
  });

  final SettingsController settingsController;
  final GlobalKey<NavigatorState> navigatorKey;

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
                    //TODO: What to do here
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
    // Glue the SettingsController to the MaterialApp.

    // Add post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (Platform.isAndroid && await _needsExactAlarmPermission()) {
        _requestExactAlarmPermission();
      } else {
        // Initialize daily activation and deactivation alarms
        platform.invokeMethod('keepScreenOn');
        await _saveSchedule(
          TimeOfDay(hour: 23, minute: 08),
          TimeOfDay(hour: 23, minute: 07),
        );
      }
    });

    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
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
      platform.invokeMethod(
          'releaseScreenOn'); // Cancel alarms when app is closed or goes inactive
    }
    super.didChangeAppLifecycleState(state);
  }
}
