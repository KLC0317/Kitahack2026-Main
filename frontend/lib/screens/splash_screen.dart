import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'login_screen.dart';

/// A stateful widget that displays an animated splash screen sequence.
/// It transitions through text displays, background expansions, and logo reveals
/// before navigating to the Login Screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// The state class for [SplashScreen] using [TickerProviderStateMixin] 
/// to handle multiple independent animation controllers.
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers for the different phases of the splash sequence
  late AnimationController _textController;     // Handles initial title/subtitle
  late AnimationController _circleController;   // Handles the background radial expansion
  late AnimationController _logoController;     // Handles the final logo reveal
  late AnimationController _teamBadgeController; // Handles the team badge reveal
  late AnimationController _particleController; // Handles the continuous background movement
  
  // Specific animation definitions for fine-grained control over transitions
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _circleScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _teamBadgeSlideAnimation;
  late Animation<double> _teamBadgeFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // --- Controller Initialization ---
    
    // Text phase: occurs over 2 seconds
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Circle expansion phase: occurs over 1.5 seconds
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Logo reveal phase: occurs over 1 second
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Team badge reveal phase: occurs over 1 second
    _teamBadgeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Continuous particle movement: loops every 3 seconds
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // --- Animation Definitions ---
    
    // Moves text off-screen to the right during the second half of the text controller
    _textSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 0),
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInBack),
    ));
    
    // Fades text in quickly at the start
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
    
    // Scales the central circle to cover the entire screen area
    _circleScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Logo slides in from the left
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(-2.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));
    
    // Standard fade-in for the logo
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));
    
    // Team badge slides in from the right
    _teamBadgeSlideAnimation = Tween<Offset>(
      begin: const Offset(2.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _teamBadgeController,
      curve: Curves.easeOutCubic,
    ));
    
    // Standard fade-in for the team badge
    _teamBadgeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _teamBadgeController,
      curve: Curves.easeIn,
    ));
    
    // Start the sequential execution of animations
    _startAnimationSequence();
  }

  /// Manages the choreography of the splash screen animations using async/await.
  Future<void> _startAnimationSequence() async {
    // Phase 1: Show and then slide out the text
    await _textController.forward();
    
    // Phase 2: Expand the radial gradient circle
    await _circleController.forward();
    
    // Phase 3: Reveal the logo from left and team badge from right simultaneously
    await Future.wait([
      _logoController.forward(),
      _teamBadgeController.forward(),
    ]);
    
    // Phase 4: Brief pause for brand recognition
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Phase 5: Transition to LoginScreen with a custom FadeTransition
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Properly clean up all controllers to prevent memory leaks
    _textController.dispose();
    _circleController.dispose();
    _logoController.dispose();
    _teamBadgeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Base dark space-themed gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1A3E),
              Color(0xFF0F0F23),
            ],
          ),
        ),
        child: Stack(
          children: [
            // LAYER 1: Dynamic background particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),
            
            // LAYER 2: Text Phase (Title and Subtitle)
            // Displays initially and then slides away to make room for the logo
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFadeAnimation.value * (1 - _textController.value * 0.5),
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Main "SAFE VISION" title with multi-color gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF4ECDC4),
                                Color(0xFF6C5CE7),
                                Color(0xFFFF6B6B),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'SAFE VISION',
                              style: GoogleFonts.orbitron(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Subtitle container with frosted-glass style border
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4ECDC4).withOpacity(0.2),
                                  const Color(0xFF6C5CE7).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF4ECDC4).withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school,
                                  color: const Color(0xFF4ECDC4),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Making Schools a Safer Place',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // LAYER 3: Circle Expansion Phase - DARKER AND MORE VIBRANT
            // A radial gradient that expands to fill the background
            AnimatedBuilder(
              animation: _circleController,
              builder: (context, child) {
                return Center(
                  child: Transform.scale(
                    scale: _circleScaleAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00D9FF), // Bright cyan center
                            const Color(0xFF4169E1), // Royal blue
                            const Color(0xFF8B00FF), // Deep purple
                            const Color(0xFF1A0033), // Very dark purple
                            const Color(0xFF0A0E27), // Original dark background
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withOpacity(0.7),
                            blurRadius: 120,
                            spreadRadius: 60,
                          ),
                          BoxShadow(
                            color: const Color(0xFF8B00FF).withOpacity(0.5),
                            blurRadius: 80,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // LAYER 4: Final Logo and Branding Phase
            // Logo slides in from left, team badge slides in from right
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo sliding in from left
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoFadeAnimation.value,
                        child: SlideTransition(
                          position: _logoSlideAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Layered outer glow shadows - MORE VIBRANT
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D9FF).withOpacity(0.8),
                                      blurRadius: 100,
                                      spreadRadius: 50,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF8B00FF).withOpacity(0.6),
                                      blurRadius: 70,
                                      spreadRadius: 30,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Internal logo housing
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF00D9FF).withOpacity(0.4),
                                      const Color(0xFF4169E1).withOpacity(0.3),
                                      const Color(0xFF8B00FF).withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF00D9FF).withOpacity(0.8),
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Transform.scale(
                                    scale: 3.5,
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Team badge sliding in from right - DARKER BACKGROUND WITH BRIGHT TEXT
                  AnimatedBuilder(
                    animation: _teamBadgeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _teamBadgeFadeAnimation.value,
                        child: SlideTransition(
                          position: _teamBadgeSlideAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              // Darker, more solid background
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1A0033).withOpacity(0.9), // Dark purple
                                  const Color(0xFF001A33).withOpacity(0.9), // Dark blue
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFF00D9FF), // Bright cyan border
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D9FF).withOpacity(0.5),
                                  blurRadius: 25,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF8B00FF).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  color: const Color(0xFF00D9FF), // Bright cyan icon
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Color(0xFF00D9FF), // Bright cyan
                                      Color(0xFF00FF88), // Bright green-cyan
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'TEAM ZESITX',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      color: Colors.white,
                                      letterSpacing: 3.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that renders a field of 80 floating particles.
/// Used to create a "starfield" or "data stream" background effect.
class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Create 80 unique particles with varying colors and speeds
    for (int i = 0; i < 80; i++) {
      // Seeded random ensures particle positions are consistent per index
      final random = Random(i);
      final x = random.nextDouble() * size.width;
      
      // Calculate vertical movement based on animation value
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + animationValue * 200) % size.height;
      
      final radius = random.nextDouble() * 3 + 1;
      
      // Gradually fade particles as the animation progresses
      final opacity = (random.nextDouble() * 0.6 + 0.2) * 
                      (1 - (animationValue * 0.3)); 
      
      // Assign one of three theme colors
      final colorChoice = random.nextInt(3);
      Color particleColor;
      
      if (colorChoice == 0) {
        particleColor = const Color(0xFF4ECDC4);
      } else if (colorChoice == 1) {
        particleColor = const Color(0xFF6C5CE7);
      } else {
        particleColor = const Color(0xFFFF6B6B);
      }
      
      // Draw the core particle
      paint.color = particleColor.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
      
      // Draw a secondary glow circle around the particle
      paint.color = particleColor.withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 2, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    // Only repaint when the animation value changes
    return oldDelegate.animationValue != animationValue;
  }
}
