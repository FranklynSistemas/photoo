import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_controller.dart';
import 'settings_select_directory.dart';
import 'folder_state.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    // Access the current folder path from FolderState
    final folderState = Provider.of<FolderState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from the dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<ThemeMode>(
                // Read the selected themeMode from the controller
                value: controller.themeMode,
                // Call the updateThemeMode method any time the user selects a theme.
                onChanged: controller.updateThemeMode,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System Theme'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light Theme'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark Theme'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: FolderPicker(), // Use FolderPicker Widget
            ),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Transition time in minutes:",
                        textAlign: TextAlign
                            .left, // Aligns the text within its natural size
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16 // Makes the text bold
                        )),
                    const SizedBox(
                        width:
                            8), // Adds a small gap between the text and the slider
                    Expanded(
                      child: Slider(
                        value: folderState.transitionTime,
                        max: 10,
                        min: 1,
                        divisions: 10,
                        label: folderState.transitionTime.round().toString(),
                        onChanged: (double value) {
                          folderState.setTransitionTime(value);
                        },
                      ),
                    ),
                    Text("${folderState.transitionTime.round()} min")
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
