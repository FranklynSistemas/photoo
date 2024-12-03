import 'package:flutter/material.dart';
import 'package:photoo/src/settings/app_state.dart';

class WidgetPositionSelector extends StatelessWidget {
  final Function(Positions) onPositionSelected;
  final Positions selectedPosition;
  final List<Positions> blockedPositions;

  const WidgetPositionSelector({
    super.key,
    required this.onPositionSelected,
    required this.selectedPosition,
    this.blockedPositions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Positions>(
      value: selectedPosition,
      onChanged: (Positions? newPosition) {
        if (newPosition != null) {
          onPositionSelected(newPosition);
        }
      },
      items: Positions.values
          .where((position) => !blockedPositions.contains(position))
          .map<DropdownMenuItem<Positions>>((Positions position) {
        return DropdownMenuItem<Positions>(
          value: position,
          child: Row(
            children: [
              Icon(
                _getIconForPosition(position),
                color:
                    position == selectedPosition ? Colors.blue : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                _getLabelForPosition(position),
                style: TextStyle(
                  color:
                      position == selectedPosition ? Colors.blue : Colors.black,
                  fontWeight: position == selectedPosition
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForPosition(Positions position) {
    switch (position) {
      case Positions.topLeft:
        return Icons.arrow_upward;
      case Positions.topRight:
        return Icons.arrow_forward;
      case Positions.center:
        return Icons.center_focus_strong;
      case Positions.bottomLeft:
        return Icons.arrow_downward;
      case Positions.bottomRight:
        return Icons.arrow_forward;
      default:
        return Icons.help;
    }
  }

  String _getLabelForPosition(Positions position) {
    switch (position) {
      case Positions.topLeft:
        return 'Top Left';
      case Positions.topRight:
        return 'Top Right';
      case Positions.center:
        return 'Center';
      case Positions.bottomLeft:
        return 'Bottom Left';
      case Positions.bottomRight:
        return 'Bottom Right';
      default:
        return '';
    }
  }
}
