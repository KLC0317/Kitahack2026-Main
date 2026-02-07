import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../widgets/school_map_2d.dart';
import 'details_screen.dart';
import 'main_navigation_screen.dart';
import '../models/alert_model.dart';

/// SchoolDigitalTwinScreen displays a real-time 2D map of the school campus
/// with live security alerts, floor selection, and interactive alert markers
class SchoolDigitalTwinScreen extends StatefulWidget {
  const SchoolDigitalTwinScreen({super.key});

  @override
  State<SchoolDigitalTwinScreen> createState() =>
      _SchoolDigitalTwinScreenState();
}

class _SchoolDigitalTwinScreenState extends State<SchoolDigitalTwinScreen>
    with TickerProviderStateMixin {
  /// Main fade-in animation controller for screen entrance
  late AnimationController _controller;
  
  /// Pulse animation controller for live indicator and alert counter
  late AnimationController _pulseController;
  
  /// Slide animation controller for bottom panel entrance
  late AnimationController _slideController;

  /// Fade animation for smooth screen appearance
  late Animation<double> _fadeAnimation;
  
  /// Pulse animation for breathing effect on live elements
  late Animation<double> _pulseAnimation;
  
  /// Slide animation for bottom panel entrance from bottom
  late Animation<Offset> _slideAnimation;

  /// Currently selected floor for map display (Ground, First, Second)
  String _selectedFloor = 'Ground';

  @override
  void initState() {
    super.initState();

    // Initialize fade-in animation (800ms duration)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize pulse animation (2s duration, repeating)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize slide animation (1.2s duration with elastic effect)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Configure fade animation curve
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Configure pulse animation for breathing effect (95% to 105% scale)
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Configure slide animation from bottom with elastic bounce
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start fade-in animation immediately
    _controller.forward();
    
    // Delay slide animation for staggered effect
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    // Clean up animation controllers to prevent memory leaks
    _controller.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Calculates the count of alerts by severity level
  /// Returns a map with keys: 'high', 'medium', 'low'
  Map<String, int> _getAlertCounts(List alerts) {
    int high = 0, medium = 0, low = 0;
    
    for (var alert in alerts) {
      switch (alert.severity.toUpperCase()) {
        case 'HIGH':
          high++;
          break;
        case 'MEDIUM':
          medium++;
          break;
        case 'LOW':
          low++;
          break;
      }
    }
    
    return {'high': high, 'medium': medium, 'low': low};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background with dark theme colors
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0a0a0a),
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                ],
              ),
            ),
          ),

          // Main content area with map and controls
          SafeArea(
            child: Column(
              children: [
                // Compact header with logo and live indicator
                _buildCompactHeader(),

                // Map area with real-time alert stream
                Expanded(
                  child: _buildMapStreamBuilder(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the compact header with logo, app name, and live indicator
  Widget _buildCompactHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // App logo with scale transform
          Transform.scale(
            scale: 2.25,
            child: Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          
          // App name with gradient shader
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFFE66D),
              ],
            ).createShader(bounds),
            child: Text(
              'SAFE VISION',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          
          // Animated live indicator with pulsing effect
          _buildLiveIndicator(),
        ],
      ),
    );
  }

  /// Builds the animated live indicator badge with pulsing glow effect
  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Calculate opacity based on pulse animation (30% to 100%)
        final opacity = 0.3 + (_pulseController.value * 0.7);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.2 * opacity),
                Colors.green.withOpacity(0.1 * opacity),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withOpacity(opacity),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3 * opacity),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing green dot
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5 * opacity),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  color: Colors.green.withOpacity(opacity),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the main map area with StreamBuilder for real-time alerts
  Widget _buildMapStreamBuilder() {
    return StreamBuilder<List<AlertModel>>(
      stream: DataService.getOngoingAlertsStream(),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        // Handle loading state (only when no data available)
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildLoadingState();
        }

        // Display map with alerts
        final alerts = snapshot.data!;
        final alertCounts = _getAlertCounts(alerts);

        return Column(
          children: [
            // Map widget with fade-in animation
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SchoolMap2D(
                  alerts: alerts,
                  selectedFloor: _selectedFloor,
                  onAlertTap: (alert) => _navigateToDetails(alert),
                ),
              ),
            ),
            
            // Bottom panel with slide-in animation
            SlideTransition(
              position: _slideAnimation,
              child: _buildUltraCompactBottomPanel(alerts, alertCounts),
            ),
          ],
        );
      },
    );
  }

  /// Builds the error state UI with retry button
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Error message container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                '$error',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: Colors.red.shade300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            
            // Retry button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry stream
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the loading state UI with spinner
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading alerts...',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the ultra-compact bottom panel with alert counter and floor selector
  Widget _buildUltraCompactBottomPanel(
      List alerts, Map<String, int> alertCounts) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.85),
            const Color(0xFF1a1a2e).withOpacity(0.85),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFE66D).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Alert counter with tap navigation to AI Summary
          Expanded(
            flex: 3,
            child: _buildAlertCounter(alerts, alertCounts),
          ),
          const SizedBox(width: 10),

          // Floor selector with compact number buttons
          _buildFloorSelector(),
        ],
      ),
    );
  }

  /// Builds the clickable alert counter with severity breakdown
  /// Tapping navigates to AI Summary screen
  Widget _buildAlertCounter(List alerts, Map<String, int> alertCounts) {
    return GestureDetector(
      onTap: () {
        // Navigate to AI Summary tab (index 1) in MainNavigationScreen
        final mainNavState = context.findAncestorStateOfType<MainNavigationScreenState>();
        mainNavState?.changeTab(1);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            // Apply pulse animation only when alerts exist
            scale: alerts.isNotEmpty ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: alerts.isNotEmpty
                      ? [
                          const Color(0xFFFF6B6B).withOpacity(0.3),
                          const Color(0xFFFF8E53).withOpacity(0.3),
                        ]
                      : [
                          Colors.green.withOpacity(0.2),
                          Colors.green.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alerts.isNotEmpty
                      ? const Color(0xFFFF6B6B).withOpacity(0.5)
                      : Colors.green.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status icon (warning or check)
                  Icon(
                    alerts.isNotEmpty
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                    color: alerts.isNotEmpty
                        ? const Color(0xFFFF6B6B)
                        : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  
                  // Alert count
                  Text(
                    '${alerts.length}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Alerts',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  // Severity breakdown (only shown when alerts exist)
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 6),
                    
                    // Severity dots (high, medium, low)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTinySeverityDot(alertCounts['high']!,
                              const Color(0xFFFF6B6B)),
                          const SizedBox(width: 3),
                          _buildTinySeverityDot(alertCounts['medium']!,
                              const Color(0xFFFF8E53)),
                          const SizedBox(width: 3),
                          _buildTinySeverityDot(alertCounts['low']!,
                              const Color(0xFF9CCC65)),
                        ],
                      ),
                    ),
                  ],
                  
                  // Arrow icon indicating clickability
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.5),
                    size: 10,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the compact floor selector with number buttons
  Widget _buildFloorSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.layers,
            color: Colors.white60,
            size: 14,
          ),
          const SizedBox(width: 6),
          _buildTinyFloorButton('1', 'Ground'),
          const SizedBox(width: 4),
          _buildTinyFloorButton('2', 'First'),
          const SizedBox(width: 4),
          _buildTinyFloorButton('3', 'Second'),
        ],
      ),
    );
  }

  /// Builds a tiny floor selection button with number display
  /// [number] - Display number (1, 2, 3)
  /// [name] - Internal floor name (Ground, First, Second)
  Widget _buildTinyFloorButton(String number, String name) {
    final isSelected = _selectedFloor == name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFloor = name;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            // Gradient for selected state, solid color for unselected
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFF8E53),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFE66D)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Text(
            number,
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a tiny severity indicator dot with count
  /// Returns empty widget if count is 0
  Widget _buildTinySeverityDot(int count, Color color) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        count.toString(),
        style: GoogleFonts.robotoMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Navigates to the details screen for a specific alert
  /// Uses custom page transition with fade and slide effects
  void _navigateToDetails(alert) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailsScreen(alert: alert),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
