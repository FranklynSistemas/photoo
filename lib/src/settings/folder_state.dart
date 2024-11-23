import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FolderState extends ChangeNotifier {
  Timer? _presentationTimer;
  String? _selectedFolder;
  double _transitionTime = 1;
  List<File> _images = []; // List to store image files
  late File _image;

  String? get selectedFolder => _selectedFolder;
  double get transitionTime => _transitionTime;

  List<File> get images => _images;
  File get image => _image;

  void setImage (File newImage) {
    _image = newImage;
    notifyListeners();
  }

  void setTransitionTime (double newValue) {
    _transitionTime = newValue;
    notifyListeners();
  }

  void setFolder(String? folder) async {
    if (await _requestStoragePermission()) {
      _selectedFolder = folder;
      _fetchImagesFromFolder(folder);
      notifyListeners();
    } else {
      print("Storage permission not granted.");
    }
  }

  void startPresentation() {
    // Stop any existing presentation to avoid duplicate timers
    _presentationTimer?.cancel();

    if (_images.isNotEmpty) {
      int index = 0;

      // Start a periodic timer
      _presentationTimer = Timer.periodic(
        Duration(seconds: _transitionTime.toInt() * 5), 
        (timer) {
          // Assign the current image to _image
          setImage(_images[index]);

          // Move to the next image
          index = (index + 1) % _images.length; // Loop back to start if end reached
        },
      );
    }
  }

  void stopPresentation() {
    // Stop the timer if active
    _presentationTimer?.cancel();
  }

  @override
  void dispose() {
    // Ensure the timer is stopped when the object is disposed
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
    print('getting directory ${directory.existsSync()}');
    print('Can read directory: ${directory.statSync()}');
    if (!directory.existsSync()) {
      _images = [];
      return;
    }
    print('getting listSync ${directory.listSync(recursive: true)}');
    // Fetch image files with supported extensions
    try {
      // Fetch image files with supported extensions
      _images = directory
          .listSync() // List all contents of the directory
          .whereType<File>() // Filter only files
          .where(
              (file) => _isImageFile(file.path)) // Check for image extensions
          .toList();
    } catch (e) {
      print("Error accessing directory: $e");
      _images = [];
    }
    print('getting images $_images');
    notifyListeners();
  }

  bool _isImageFile(String path) {
    print('_isImageFile $path');
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
      // Permission already granted
      print('Storage permission is granted $storageStatus');
      return true;
    } else if (storageStatus.isDenied) {
      print('Storage permission is denied $storageStatus');
      return storageStatus.isGranted;
    } else if (storageStatus.isPermanentlyDenied) {
      // Permission permanently denied
      print("Permission is permanently denied. Open settings.");
      await openAppSettings();
      return false;
    }

    return false;
  }
}
