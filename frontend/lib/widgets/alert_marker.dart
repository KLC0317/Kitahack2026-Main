import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alert_model.dart';

/// Animated marker widget for displaying alerts on the floor plan
/// Features pulsing animation and severity-based color coding
class AlertMarker extends StatefulWidget {
  /// The alert data to display
  final AlertModel alert;
  
  /// Callback when the marker is tapped
  final VoidCallback onTap;

  const AlertMarker({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  State<AlertMarker> createState() => _AlertMarkerState();
}

class _AlertMarkerState extends State<AlertMarker>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pulsing effect
  late AnimationController _controller;
  
  /// Animation for the pulse scale effect
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulsing animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the color based on alert severity
  Color _getSeverityColor() {
    switch (widget.alert.severity.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.yellow.shade700;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Pulsing outer ring with fade effect
              Container(
                width: 50 + (15 * _pulseAnimation.value),
                height: 50 + (15 * _pulseAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: severityColor.withOpacity(0.2 * (2 - _pulseAnimation.value)),
                  border: Border.all(
                    color: severityColor.withOpacity(0.4 * (2 - _pulseAnimation.value)),
                    width: 2,
                  ),
                ),
              ),

              // Main circular marker with icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: severityColor,
                  boxShadow: [
                    BoxShadow(
                      color: severityColor.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              // Severity level badge (H/M/L)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: severityColor, width: 2),
                  ),
                  child: Text(
                    widget.alert.severity.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
