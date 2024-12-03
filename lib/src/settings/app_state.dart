import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for clock positions
enum Positions {
  topLeft,
  topRight,
  center,
  bottomLeft,
  bottomRight,
}

class AppState extends ChangeNotifier {
  Timer? _presentationTimer;
  String? _selectedFolder;
  double _transitionTime = 1;
  List<File> _images = []; // List to store image files
  File? _image;
  Positions _clockPosition = Positions.center;
  bool _showClock = false;
  Positions _dayWetherPosition = Positions.bottomRight;

  String? get selectedFolder => _selectedFolder;
  double get transitionTime => _transitionTime;

  List<File> get images => _images;
  File? get image => _image; // Nullable getter
  Positions get clockPosition => _clockPosition;
  bool get showClock => _showClock;
  Positions get dayWetherPosition => _dayWetherPosition;

  AppState() {
    _initializeState(); // Use an async initialization pattern
  }

  Future<void> _initializeState() async {
    await _loadSavedPreferences();
    if (_selectedFolder != null && _selectedFolder!.isNotEmpty) {
      _fetchImagesFromFolder(_selectedFolder); // Fetch images immediately
      notifyListeners();
      startPresentation();
    }
  }

  void setShowClock(bool newValue) {
    _showClock = newValue;
    _saveShowClock();
    notifyListeners();
  }

  void setClockPosition(Positions newPosition) {
    _clockPosition = newPosition;
    _saveClockPosition();
    notifyListeners();
  }

  void setDayWetherPosition(Positions newPosition) {
    _dayWetherPosition = newPosition;
    _saveDayWetherPosition();
    notifyListeners();
  }

  void setImage(File newImage) {
    _image = newImage;
    notifyListeners();
  }

  void setTransitionTime(double newValue) {
    _transitionTime = newValue;
    _saveTransitionTime(); // Save the transition time
    notifyListeners();
  }

  void setFolder(String? folder) async {
    if (await _requestStoragePermission()) {
      _selectedFolder = folder;
      _saveSelectedFolder(folder); // Save the selected folder
      _fetchImagesFromFolder(folder);
      startPresentation();
      notifyListeners();
    } else {
      print("Storage permission not granted.");
    }
  }

  void startPresentation() {
    _presentationTimer?.cancel();
    print("Start presentation $_image");

    if (_selectedFolder == null || _selectedFolder!.isEmpty) {
      // If folder is not selected or empty, do not start the presentation
      print("No folder selected or folder is empty. $_selectedFolder");
      return;
    }

    // Fetch images from the folder if not already done
    if (_images.isEmpty) {
      _fetchImagesFromFolder(_selectedFolder);
    }

    if (_images.isNotEmpty) {
      int index = 0;
      setImage(_images.first);
      _presentationTimer = Timer.periodic(
        Duration(seconds: _transitionTime.toInt() * 5),
        (timer) {
          setImage(_images[index]);
          index = (index + 1) % _images.length;
        },
      );
    }
  }

  void stopPresentation() {
    _presentationTimer?.cancel();
  }

  @override
  void dispose() {
    _presentationTimer?.cancel();
    super.dispose();
  }

  void _fetchImagesFromFolder(String? folder) async {
    print('getting folder $folder');
    if (folder == null) {
      _images = [];
      return;
    }

    final directory = Directory(folder);
    if (!directory.existsSync()) {
      _images = [];
      return;
    }

    try {
      _images = directory
          .listSync()
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();
    } catch (e) {
      print("Error accessing directory: $e");
      _images = [];
    }

    notifyListeners();
  }

  bool _isImageFile(String path) {
    final extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  Future<bool> _requestStoragePermission() async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;
    final storageStatus = android.version.sdkInt < 30
        ? await Permission.storage.request()
        : await Permission.manageExternalStorage.request();

    if (storageStatus.isGranted) {
      return true;
    } else if (storageStatus.isDenied) {
      return storageStatus.isGranted;
    } else if (storageStatus.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Save selected folder to shared preferences
  Future<void> _saveSelectedFolder(String? folder) async {
    final prefs = await SharedPreferences.getInstance();
    if (folder != null) {
      prefs.setString('selectedFolder', folder);
    }
  }

  // Load selected folder from shared preferences
  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedFolder = prefs.getString('selectedFolder');
    _transitionTime = prefs.getDouble('transitionTime') ?? 1.0;
    _showClock = prefs.getBool('showClock') ?? false;
    String? clockPositionString = prefs.getString('clockPosition');
    if (clockPositionString != null) {
      _clockPosition = Positions.values.firstWhere(
        (e) => e.toString().split('.').last == clockPositionString,
        orElse: () => Positions
            .center, // Default to Positions.center if not found
      );
    } else {
      _clockPosition = Positions.center; // Default if no saved value
    }
    notifyListeners();
  }

  // Save transition time to shared preferences
  Future<void> _saveTransitionTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('transitionTime', _transitionTime);
  }

  // Save show clock to shared preferences
  Future<void> _saveShowClock() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showClock', _showClock);
  }

  // Save clock position to shared preferences
  Future<void> _saveClockPosition() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('clockPosition', _clockPosition.toString().split('.').last);
  }

  Future<void> _saveDayWetherPosition() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('dayWetherPosition', _dayWetherPosition.toString().split('.').last);
  }
}
