import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floor selector widget for navigating between different building floors
/// Displays a vertical list of floor buttons with visual feedback for selection
class FloorSelector extends StatelessWidget {
  /// Currently selected floor
  final String selectedFloor;
  
  /// List of available floors to display
  final List<String> availableFloors;
  
  /// Callback when a floor is selected
  final Function(String) onFloorSelected;

  const FloorSelector({
    super.key,
    required this.selectedFloor,
    required this.availableFloors,
    required this.onFloorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: availableFloors.map((floor) {
          final isSelected = floor == selectedFloor;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => onFloorSelected(floor),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getFloorLabel(floor),
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Converts floor name to abbreviated label
  /// Ground -> G, First -> 1, Second -> 2, etc.
  String _getFloorLabel(String floor) {
    switch (floor) {
      case 'Ground':
        return 'G';
      case 'First':
        return '1';
      case 'Second':
        return '2';
      case 'Third':
        return '3';
      default:
        return floor.substring(0, 1).toUpperCase();
    }
  }
}
