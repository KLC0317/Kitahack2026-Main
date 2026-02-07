import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alert_model.dart';
import '../models/school_location.dart';

/// 2D interactive map widget displaying school floor plans with alert markers
/// Supports pan, zoom, and multi-floor navigation with real-time alert visualization
class SchoolMap2D extends StatefulWidget {
  /// List of alerts to display on the map
  final List<AlertModel> alerts;
  
  /// Callback when an alert marker is tapped
  final Function(AlertModel) onAlertTap;
  
  /// Currently selected floor to display
  final String selectedFloor;

  const SchoolMap2D({
    super.key,
    required this.alerts,
    required this.onAlertTap,
    required this.selectedFloor,
  });

  @override
  State<SchoolMap2D> createState() => _SchoolMap2DState();
}

class _SchoolMap2DState extends State<SchoolMap2D>
    with SingleTickerProviderStateMixin {
  /// Animation controller for pulsing alert markers
  late AnimationController _pulseController;
  
  /// Controller for pan and zoom transformations
  final TransformationController _transformationController = TransformationController();
  
  // ============================================
  // IMAGE CONFIGURATION
  // ============================================
  
  /// Original width of the map images in pixels
  static const double MAP_IMAGE_WIDTH = 1145.0;
  
  /// Original height of the map images in pixels
  static const double MAP_IMAGE_HEIGHT = 1269.0;
  
  /// Map of floor names to their corresponding image assets
  static const Map<String, String> MAP_IMAGES = {
    'Ground': 'assets/maps/FLOOR1.png',
    'First': 'assets/maps/FLOOR2.png',
    'Second': 'assets/maps/FLOOR3.png',
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize pulsing animation for alert markers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Returns all alerts (can be extended to filter by floor)
  List<AlertModel> _getFilteredAlerts() {
    return widget.alerts;
  }

  /// Gets the map image path for the currently selected floor
  String _getCurrentMapImage() {
    return MAP_IMAGES[widget.selectedFloor] ?? MAP_IMAGES['Ground']!;
  }

  @override
  Widget build(BuildContext context) {
    SchoolMapData.getLocationsByFloor(widget.selectedFloor);
    final filteredAlerts = _getFilteredAlerts();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Calculate scale factors for both dimensions
        final scaleX = screenWidth / MAP_IMAGE_WIDTH;
        final scaleY = screenHeight / MAP_IMAGE_HEIGHT;
        
        // Use the larger scale to fill the screen
        final adaptiveScale = scaleX > scaleY ? scaleX : scaleY;
        
        // Calculate actual display dimensions
        final displayWidth = MAP_IMAGE_WIDTH * adaptiveScale;
        final displayHeight = MAP_IMAGE_HEIGHT * adaptiveScale;

        return Stack(
          children: [
            // Main map container
            Positioned.fill(
              child: Container(
                color: const Color(0xFF252525),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: adaptiveScale,
                  maxScale: adaptiveScale * 4.0,
                  boundaryMargin: EdgeInsets.zero,
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: true,
                  onInteractionUpdate: (details) {
                    setState(() {
                    });
                  },
                  child: SizedBox(
                    width: displayWidth,
                    height: displayHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Floor plan image
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Image.asset(
                            _getCurrentMapImage(),
                            width: displayWidth,
                            height: displayHeight,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildErrorWidget();
                            },
                          ),
                        ),
                        
                        // Alert markers overlay
                        ...filteredAlerts.map((alert) {
                          final location = SchoolMapData.getLocationByName(
                            alert.location,
                            'A',
                            widget.selectedFloor,
                          );
                          if (location == null) return const SizedBox.shrink();

                          final alertPos = location.alertPosition;
                          
                          // Scale alert position to match display size
                          final scaledX = (alertPos.dx / MAP_IMAGE_WIDTH) * displayWidth;
                          final scaledY = (alertPos.dy / MAP_IMAGE_HEIGHT) * displayHeight;

                          return Positioned(
                            left: scaledX - 15,
                            top: scaledY - 15,
                            child: _buildAlertMarker(alert, location),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Zoom controls positioned at bottom right
            Positioned(
              right: 16,
              bottom: 100,
              child: _buildZoomControls(adaptiveScale),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // UI WIDGET METHODS
  // ============================================

  /// Builds error widget when map image fails to load
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Map Image Not Found',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getCurrentMapImage(),
                  style: GoogleFonts.robotoMono(
                    color: Colors.red.shade300,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds zoom control buttons (zoom in, reset view)
  Widget _buildZoomControls(double minScale) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.7),
            const Color(0xFF1a1a2e).withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            tooltip: 'Zoom In',
            onPressed: () {
              final matrix = _transformationController.value.clone();
              matrix.scale(1.2);
              _transformationController.value = matrix;
              setState(() {});
            },
          ),
          
          // Divider
          Container(
            height: 1,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Reset view button
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.white, size: 20),
            tooltip: 'Reset View',
            onPressed: () {
              setState(() {
                _transformationController.value = Matrix4.identity();
              });
            },
          ),
        ],
      ),
    );
  }

  /// Builds an animated alert marker with pulsing effect
  Widget _buildAlertMarker(AlertModel alert, SchoolLocation location) {
    Color severityColor = _getSeverityColor(alert.severity);

    return GestureDetector(
      onTap: () => widget.onAlertTap(alert),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Pulsing outer ring
              Container(
                width: 38 + (8 * _pulseController.value),
                height: 38 + (8 * _pulseController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: severityColor.withOpacity(0.2 * (1 - _pulseController.value)),
                  border: Border.all(
                    color: severityColor.withOpacity(0.4 * (1 - _pulseController.value)),
                    width: 1,
                  ),
                ),
              ),
              
              // Main marker circle with icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: severityColor,
                  boxShadow: [
                    BoxShadow(
                      color: severityColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),

              // Severity level badge
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor, width: 1),
                  ),
                  child: Text(
                    alert.severity.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.robotoMono(
                      fontSize: 7,
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

  /// Returns color based on alert severity level
  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return const Color(0xFF9CCC65);
      default:
        return Colors.orange;
    }
  }
}
