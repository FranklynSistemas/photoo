import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ScheduleWakelock extends StatelessWidget {
  const ScheduleWakelock({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the current folder path from AppState
    final appState = Provider.of<AppState>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTimeTile(
                context: context,
                title: "App wake-up time",
                icon: Icons.alarm,
                time: appState.onTime,
                onTimePicked: (picked) => appState.setOnTime(picked),
              ),
            ),
            const SizedBox(
              width: 1, // Ensure proper constraints for the divider
              child: VerticalDivider(
                thickness: 10,
                color: Colors.grey,
              ),
            ),
            Expanded(
              child: _buildTimeTile(
                context: context,
                title: "App sleep time",
                icon: Icons.alarm_off,
                time: appState.offTime,
                onTimePicked: (picked) => appState.setOffTime(picked),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required TimeOfDay time,
    required Function(TimeOfDay) onTimePicked,
  }) {
    return InkWell(
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onTimePicked(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "$title\n${time.format(context)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}