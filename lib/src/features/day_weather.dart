import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/weather.dart';

import '../providers/location_provider.dart';
import 'weather_view.dart';

class DayWeatherWidget extends StatefulWidget {
  const DayWeatherWidget({Key? key}) : super(key: key);

  @override
  State<DayWeatherWidget> createState() => _DayWeatherWidgetState();
}

class _DayWeatherWidgetState extends State<DayWeatherWidget> {
  Weather? _currentWeather;
  bool _isLoading = true;

  final WeatherFactory wf = WeatherFactory("373f20fc348ce72421dbe5a00b8ea16d");
  final double defaultLat = 40.416775;
  final double defaultLong = -3.703790;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start listening for changes in location
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;

    if (position != null) {
      try {
        final weather = await wf.currentWeatherByLocation(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _currentWeather = weather;
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching weather: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Listen for location changes, and re-fetch weather when it changes
        if (locationProvider.currentPosition != null && _isLoading) {
          _fetchWeather();
        }

        // Show loading state while fetching
        if (_isLoading) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Loading weather...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _currentWeather != null
                  ? WeatherView(currentWeather: _currentWeather)
                  : const Text(
                      "Failed to fetch weather data",
                      style: TextStyle(color: Colors.white),
                    ),
            ],
          ),
        );
      },
    );
  }
}