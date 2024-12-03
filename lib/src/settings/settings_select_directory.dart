import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class FolderPicker extends StatelessWidget {
  const FolderPicker({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the current folder path from FolderState
    final folderState = Provider.of<AppState>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display the current selected folder path
        TextFormField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: "Selected Folder",
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: folderState.selectedFolder),
        ),
        const SizedBox(height: 10),
        // Button to open the folder picker
        ElevatedButton(
          onPressed: () async {
            // Open folder picker and update app state
            String? selectedFolder = await FilePicker.platform.getDirectoryPath();
            if (selectedFolder != null) {
              folderState.setFolder(selectedFolder);
            }
          },
          child: const Text("Select Folder"),
        ),
      ],
    );
  }
}
