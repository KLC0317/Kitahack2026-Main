import 'package:flutter/material.dart';

/// Animated pulsing marker for displaying alerts with severity-based colors
/// Features a pulsing animation effect and tap interaction
class PulsingAlertMarker extends StatefulWidget {
  /// Severity level of the alert (HIGH, MEDIUM, LOW)
  final String severity;
  
  /// Callback when the marker is tapped
  final VoidCallback onTap;

  const PulsingAlertMarker({
    super.key,
    required this.severity,
    required this.onTap,
  });

  @override
  State<PulsingAlertMarker> createState() => _PulsingAlertMarkerState();
}

class _PulsingAlertMarkerState extends State<PulsingAlertMarker>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pulsing effect
  late AnimationController _controller;
  
  /// Animation for the pulse scale
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulsing animation that repeats continuously
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the color based on alert severity level
  Color _getSeverityColor() {
    switch (widget.severity.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.yellow;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring with fade effect
              Container(
                width: 50 * _animation.value,
                height: 50 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.3 * (1 - _animation.value)),
                ),
              ),
              
              // Inner solid marker with icon
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
