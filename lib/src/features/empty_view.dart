import 'package:flutter/material.dart';
import 'package:photoo/src/settings/settings_view.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.selectedFolder,
  });

  final String? selectedFolder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: selectedFolder != null
          ? const Text("No images available :(.")
          : Row(
              mainAxisSize: MainAxisSize.min, // Align the content in the center
              children: [
                const Text("No selected Folder, please select one on Settings"),
                const SizedBox(width: 8), // Add some spacing between text and button
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                     Navigator.restorablePushNamed(context, SettingsView.routeName);
                  },
                ),
              ],
            ),
    );
  }
}
