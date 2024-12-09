import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NetworkFolderPicker extends StatefulWidget {
  final ValueChanged<String>
      onFolderSelected; // Callback to pass selected folder

  // Constructor to accept the callback
  NetworkFolderPicker({required this.onFolderSelected});

  @override
  _NetworkFolderPickerState createState() => _NetworkFolderPickerState();
}

class _NetworkFolderPickerState extends State<NetworkFolderPicker> {
  static const platform = MethodChannel('com.example.photoo/screen');

  // List of available network shares
  List<String> networkShares = [];

  // Function to list available network shares
  Future<void> _listNetworkShares() async {
    try {
      // Call Kotlin method to get available network shares
      final List<dynamic> result =
          await platform.invokeMethod('listNetworkShares');
      setState(() {
        networkShares = List<String>.from(result);
      });
    } on PlatformException catch (e) {
      print("Failed to list network shares: ${e.message}");
    }
  }

  // Function to discover folders from a selected share
  Future<void> _selectFolder(String sharePath) async {
    try {
      // Example IP and folder path
      String ip = "192.168.1.10";
      String folderPath = sharePath;

      // Call Kotlin method to get network folders from the selected share
      final List<dynamic> result =
          await platform.invokeMethod('getNetworkFolders', {
        'ip': ip,
        'folderPath': folderPath,
      });

      // Show the available folders (you can adjust this as needed)
      print("Network Folders: $result");

      // Use the callback to pass the selected folder path back to the parent widget
      widget.onFolderSelected(folderPath);
    } on PlatformException catch (e) {
      print("Failed to get network folders: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Folder Picker')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _listNetworkShares,
            child: Text('List Network Shares'),
          ),
          if (networkShares.isNotEmpty)
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: networkShares.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(networkShares[index]),
                    onTap: () => _selectFolder(networkShares[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
