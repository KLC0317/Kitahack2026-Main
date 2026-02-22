import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Map control widget for toggling view modes and resetting the view
/// Provides 2D/3D toggle and reset functionality with a styled control bar
class MapControls extends StatelessWidget {
  /// Whether the map is currently in 3D mode
  final bool is3DMode;
  
  /// Callback to toggle between 2D and 3D view modes
  final VoidCallback onToggleView;
  
  /// Callback to reset the view to default position/zoom
  final VoidCallback onResetView;

  const MapControls({
    super.key,
    required this.is3DMode,
    required this.onToggleView,
    required this.onResetView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2D/3D toggle button
          _buildControlButton(
            icon: is3DMode ? Icons.map : Icons.view_in_ar,
            label: is3DMode ? '2D' : '3D',
            onTap: onToggleView,
          ),
          
          // Divider between buttons
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white24,
          ),
          
          // Reset view button
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Reset',
            onTap: onResetView,
          ),
        ],
      ),
    );
  }

  /// Builds a control button with icon and label
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
