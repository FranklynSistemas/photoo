import 'package:flutter/material.dart';
import 'package:photoo/src/features/analog_clock.dart';
import 'package:photoo/src/features/day_weather.dart';
import 'package:photoo/src/features/empty_view.dart';
import 'package:photoo/src/features/photo_viewer.dart';
import 'package:provider/provider.dart';

import '../settings/app_state.dart';
import '../settings/settings_view.dart';

const padding = 50.0;

/// Displays a single image with a blurred background.
class PhotosView extends StatefulWidget {
  const PhotosView({super.key});

  static const routeName = '/';

  @override
  State<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends State<PhotosView> {
  @override
  void initState() {
    super.initState();
  }

  bool _hasStartedPresentation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasStartedPresentation) {
      _hasStartedPresentation = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final appState = Provider.of<AppState>(context, listen: false);
        print("Start presentation from didChangeDependencies");
        appState.startPresentation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final imageFile = appState.image;
    final selectedFolder = appState.selectedFolder;
    final clockPosition = appState.clockPosition;
    final showClock = appState.showClock;
    final dayWetherPosition = appState.dayWetherPosition;

    // Calculate the positioning values based on the selected clock position
    var positionedClock;
    switch (clockPosition) {
      case Positions.topLeft:
        positionedClock = const Positioned(
          top: padding,
          left: padding,
          child: AnalogClock(),
        );
        break;
      case Positions.topRight:
        positionedClock = const Positioned(
          top: padding,
          right: padding,
          child: AnalogClock(),
        );
        break;
      case Positions.center:
        // Center is handled by the Center widget itself
        break;
      case Positions.bottomLeft:
        positionedClock = const Positioned(
          bottom: padding,
          left: padding,
          child: AnalogClock(),
        );
        break;
      case Positions.bottomRight:
        positionedClock = const Positioned(
          bottom: padding,
          right: padding,
          child: AnalogClock(),
        );
        break;
    }

    var positionedDayWeather;
    switch (dayWetherPosition) {
      case Positions.topLeft:
          positionedDayWeather = const Positioned(
              top: padding,
              left: padding,
              child: DayWeatherWidget(),
            );
        break;
      case Positions.topRight:
          positionedDayWeather = const Positioned(
              top: padding,
              right: padding,
              child: DayWeatherWidget(),
            );
        break;
       
      case Positions.bottomLeft:
        positionedDayWeather = const Positioned(
              bottom: padding,
              left: padding,
              child: DayWeatherWidget(),
            );
       break;
      case Positions.bottomRight:
      positionedDayWeather = const Positioned(
              bottom: padding,
              right: padding,
              child: DayWeatherWidget(),
            );
      break;
      default:
    }

    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          imageFile != null
              ? PhotoViewer(imageFile: imageFile)
              : EmptyView(selectedFolder: selectedFolder),
          // Settings button in the top-right corner
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.restorablePushNamed(context, SettingsView.routeName);
              },
            ),
          ),
          // Positioned analog clock
          if (showClock && clockPosition != Positions.center)
            positionedClock,
          // Centered clock (if the position is center)
          if (showClock && clockPosition == Positions.center)
            const Center(child: AnalogClock()),
          if (positionedDayWeather != null)
            positionedDayWeather,
        ],
      ),
    ));
  }

  @override
  void dispose() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.stopPresentation();
    super.dispose();
  }
}
