import 'package:flutter/material.dart';
import 'package:weather/weather.dart';

const iconSize = 30.0;

class WeatherView extends StatelessWidget {
  const WeatherView({
    super.key,
    required Weather? currentWeather,
  }) : _currentWeather = currentWeather;

  final Weather? _currentWeather;

  // Helper method to map weather description to an icon
  Widget? getWeatherIcon(String? description) {
    if (description == null) return null;

    if (description.contains('rain')) {
      return const Icon(Icons.umbrella, color: Colors.blue, size: iconSize);
    } else if (description.contains('clear')) {
     // Check if it is nighttime
      final now = DateTime.now();
      final isNightTime = _currentWeather?.sunset != null &&
          _currentWeather?.sunrise != null &&
          (now.isAfter(_currentWeather!.sunset!) || now.isBefore(_currentWeather.sunrise!));
      if (isNightTime) {
        return const Icon(Icons.nightlight_round, color: Colors.yellow, size: iconSize);
      } else {
        return const Icon(Icons.wb_sunny, color: Colors.yellow, size: iconSize);
      }
    } else if (description.contains('cloud')) {
      return const Icon(Icons.cloud, color: Colors.grey, size: iconSize);
    } else if (description.contains('snow')) {
      return const Icon(Icons.ac_unit, color: Colors.lightBlue, size: iconSize);
    } else {
      return const Icon(Icons.help_outline, color: Colors.white, size: iconSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = _currentWeather?.weatherDescription;
    final temperature = _currentWeather?.temperature?.celsius?.toStringAsFixed(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Add weather icon
        if (description != null) getWeatherIcon(description) ?? const SizedBox.shrink(),
        const SizedBox(width: 8), // Space between icon and text
        Text(
          "$description, ${temperature ?? '--'}°C",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}