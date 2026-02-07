import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';

/// A stateful widget that displays an animated login transition screen.
/// 
/// This screen shows a success animation with various effects including:
/// - A scaling circle with gradient colors
/// - An animated check mark
/// - Ripple effects
/// - Particle animations
/// - Text fade-in effects
/// - Glow pulse effects
/// 
/// The animation sequence runs automatically and calls [onComplete] when finished.
class LoginTransitionScreen extends StatefulWidget {
  /// Callback function that is invoked when the animation sequence completes.
  final VoidCallback onComplete;
  
  /// Creates a [LoginTransitionScreen] widget.
  /// 
  /// The [onComplete] parameter is required and will be called after all
  /// animations have finished playing.
  const LoginTransitionScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<LoginTransitionScreen> createState() => _LoginTransitionScreenState();
}

/// State class for [LoginTransitionScreen] that manages multiple animation controllers.
/// 
/// Uses [TickerProviderStateMixin] to provide vsync for animation controllers.
class _LoginTransitionScreenState extends State<LoginTransitionScreen>
    with TickerProviderStateMixin {
  /// Main animation controller for the overall transition (2500ms duration).
  late AnimationController _mainController;
  
  /// Controller for particle animation effects (1200ms duration).
  late AnimationController _particleController;
  
  /// Controller for ripple wave effects (1000ms duration).
  late AnimationController _rippleController;
  
  /// Controller for text fade-in animation (800ms duration).
  late AnimationController _textController;
  
  /// Controller for check mark drawing animation (800ms duration).
  late AnimationController _checkController;
  
  /// Controller for continuous glow pulse effect (1500ms duration, repeating).
  late AnimationController _glowController;
  
  /// Animation for scaling the success circle from 0 to 1.
  late Animation<double> _scaleAnimation;
  
  /// Animation for fading out the entire screen at the end.
  late Animation<double> _fadeAnimation;
  
  /// Animation for progressively drawing the check mark.
  late Animation<double> _checkAnimation;
  
  /// Animation for fading in the success text.
  late Animation<double> _textFadeAnimation;
  
  /// Animation for pulsing glow effect around the success circle.
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize main animation controller with 2.5 second duration
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Initialize particle controller for simpler particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Initialize ripple effect controller
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Initialize text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize check mark animation controller
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize glow pulse controller with repeating animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Configure scale animation with ease-out-back curve for bouncy effect
    // Animates from 0% to 40% of main controller duration
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    ));
    
    // Configure fade animation for final screen fade-out
    // Animates from 70% to 100% of main controller duration
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInCubic),
    ));
    
    // Configure check mark drawing animation with smooth ease-in-out
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
    
    // Configure text fade-in animation with ease-in curve
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    // Configure glow pulse animation between 60% and 100% opacity
    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation sequence
    _startAnimationSequence();
  }

  /// Starts the coordinated animation sequence with staggered delays.
  /// 
  /// The sequence is:
  /// 1. Main animation starts immediately
  /// 2. Ripple effect starts after 150ms
  /// 3. Check mark animation starts after 300ms
  /// 4. Particle animation starts after 400ms
  /// 5. Text animation starts after 600ms
  /// 6. Complete callback is triggered after 1600ms
  void _startAnimationSequence() async {
    // Start main animation immediately
    _mainController.forward();
    
    // Start ripple after a short delay
    await Future.delayed(const Duration(milliseconds: 150));
    _rippleController.forward();
    
    // Start check mark animation
    await Future.delayed(const Duration(milliseconds: 300));
    _checkController.forward();
    
    // Start particle animation
    await Future.delayed(const Duration(milliseconds: 400));
    _particleController.forward();
    
    // Start text animation
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    
    // Wait for animations to complete then trigger navigation callback
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    // Dispose all animation controllers to free resources
    _mainController.dispose();
    _particleController.dispose();
    _rippleController.dispose();
    _textController.dispose();
    _checkController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for positioning calculations
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        // Listen to all animation controllers for rebuilds
        animation: Listenable.merge([
          _mainController,
          _particleController,
          _rippleController,
          _textController,
          _checkController,
          _glowController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Animated gradient background that transitions colors
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      // Interpolate colors based on main controller progress
                      Color.lerp(
                        const Color(0xFF0a0a0a),
                        const Color(0xFF1a1a2e),
                        _mainController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        _mainController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF16213e),
                        const Color(0xFF0f3460),
                        _mainController.value,
                      )!,
                    ],
                  ),
                ),
              ),
              
              // Ripple effect layer - only shown when animation has started
              if (_rippleController.value > 0)
                Center(
                  child: CustomPaint(
                    size: Size(size.width, size.height),
                    painter: RipplePainter(
                      progress: _rippleController.value,
                    ),
                  ),
                ),
              
              // Simple particle effect layer - only shown when animation has started
              if (_particleController.value > 0)
                CustomPaint(
                  size: size,
                  painter: SimpleParticlePainter(
                    progress: _particleController.value,
                    center: Offset(size.width / 2, size.height / 2),
                  ),
                ),
              
              // Main content layer with success circle and text
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success circle with check mark and rotating rings
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Gradient from red to orange to yellow
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFF6B6B).withOpacity(0.9),
                                const Color(0xFFFF8E53).withOpacity(0.9),
                                const Color(0xFFFFE66D).withOpacity(0.9),
                              ],
                            ),
                            // Animated glow shadows that pulse
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withOpacity(0.4 * _glowAnimation.value),
                                blurRadius: 40 * _glowAnimation.value,
                                spreadRadius: 10 * _glowAnimation.value,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFFE66D).withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 50 * _glowAnimation.value,
                                spreadRadius: 15 * _glowAnimation.value,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Animated check mark - centered in the circle
                              Center(
                                child: CustomPaint(
                                  size: const Size(70, 70),
                                  painter: CheckMarkPainter(
                                    progress: _checkAnimation.value,
                                  ),
                                ),
                              ),
                              
                              // Rotating outer ring - appears after 20% of main animation
                              if (_mainController.value > 0.2)
                                Center(
                                  child: Transform.rotate(
                                    angle: _mainController.value * 2 * math.pi,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          width: 2,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Static inner ring for depth effect
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 1.5,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Success text section with gradient and loading indicator
                      Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Column(
                          children: [
                            // "Welcome Back!" text with gradient shader
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B6B),
                                  Color(0xFFFFE66D),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'Welcome Back!',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // "Login Successful" subtitle text
                            Text(
                              'Login Successful',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Circular loading indicator
                            SizedBox(
                              width: 35,
                              height: 35,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFFFE66D).withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Subtle sparkle effects - 6 sparkles positioned in a circle
              // Only shown after 30% of particle animation
              if (_particleController.value > 0.3)
                ...List.generate(6, (index) {
                  // Calculate position in a circle around the center
                  final angle = (index / 6) * 2 * math.pi;
                  final distance = 120 + (_particleController.value * 60);
                  final x = size.width / 2 + math.cos(angle) * distance;
                  final y = size.height / 2 + math.sin(angle) * distance;
                  // Fade out as animation progresses
                  final opacity = (1 - _particleController.value) * 0.7;
                  
                  return Positioned(
                    left: x - 8,
                    top: y - 8,
                    child: Opacity(
                      opacity: opacity,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 16,
                        // Cycle through three colors for variety
                        color: index % 3 == 0
                            ? const Color(0xFFFF6B6B)
                            : index % 3 == 1
                                ? const Color(0xFFFF8E53)
                                : const Color(0xFFFFE66D),
                        shadows: [
                          Shadow(
                            color: (index % 3 == 0
                                ? const Color(0xFFFF6B6B)
                                : index % 3 == 1
                                    ? const Color(0xFFFF8E53)
                                    : const Color(0xFFFFE66D)).withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter that draws animated particles radiating from a center point.
/// 
/// Creates 20 particles that move outward and fade as the animation progresses.
/// Each particle has a random angle, distance, and size for variety.
class SimpleParticlePainter extends CustomPainter {
  /// Current progress of the particle animation (0.0 to 1.0).
  final double progress;
  
  /// Center point from which particles radiate.
  final Offset center;

  /// Creates a [SimpleParticlePainter].
  /// 
  /// [progress] controls the animation state.
  /// [center] defines the origin point for particles.
  SimpleParticlePainter({
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Use fixed seed for consistent particle positions
    final random = math.Random(42);

    // Draw 20 particles for a clean, minimal effect
    for (int i = 0; i < 20; i++) {
      // Calculate particle position based on angle and distance
      final angle = (i / 20) * 2 * math.pi + (random.nextDouble() * 0.5);
      final distance = progress * (100 + random.nextDouble() * 60);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      // Fade out particles as they move away
      final opacity = (1 - progress) * 0.6;
      final particleSize = 2 + random.nextDouble() * 2;
      
      // Cycle through three gradient colors
      final colors = [
        const Color(0xFFFF6B6B),
        const Color(0xFFFF8E53),
        const Color(0xFFFFE66D),
      ];
      final color = colors[i % 3];
      
      // Draw solid particle circle
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
      
      // Add subtle glow effect with radial gradient
      final glowGradient = RadialGradient(
        colors: [
          color.withOpacity(opacity * 0.4),
          Colors.transparent,
        ],
      );
      
      paint.shader = glowGradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: particleSize * 2),
      );
      canvas.drawCircle(Offset(x, y), particleSize * 2, paint);
      paint.shader = null;
    }
  }

  @override
  bool shouldRepaint(SimpleParticlePainter oldDelegate) => true;
}

/// Custom painter that draws expanding ripple wave effects.
/// 
/// Creates 2 concentric ripples that expand outward and fade.
/// Each ripple is staggered by 25% of the animation progress.
class RipplePainter extends CustomPainter {
  /// Current progress of the ripple animation (0.0 to 1.0).
  final double progress;

  /// Creates a [RipplePainter].
  /// 
  /// [progress] controls the expansion and fade of ripples.
  RipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw 2 ripples with staggered timing
    for (int i = 0; i < 2; i++) {
      // Calculate individual ripple progress with 25% delay between ripples
      final rippleProgress = (progress - i * 0.25).clamp(0.0, 1.0);
      if (rippleProgress <= 0) continue;
      
      // Expand radius based on progress
      final radius = rippleProgress * size.width * 0.6;
      // Fade out as ripple expands
      final opacity = (1 - rippleProgress) * 0.4;
      
      // Alternate between two colors
      final colors = [
        const Color(0xFFFF6B6B),
        const Color(0xFFFFE66D),
      ];
      
      paint.color = colors[i % 2].withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}

/// Custom painter that draws an animated check mark.
/// 
/// The check mark is drawn in two stages:
/// 1. First 50% of progress: draws the downward stroke
/// 2. Last 50% of progress: draws the upward stroke
/// 
/// Includes a subtle glow effect for visual enhancement.
class CheckMarkPainter extends CustomPainter {
  /// Current progress of the check mark drawing (0.0 to 1.0).
  final double progress;

  /// Creates a [CheckMarkPainter].
  /// 
  /// [progress] controls how much of the check mark is drawn.
  CheckMarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Main check mark stroke
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Define check mark coordinates (centered in the circle)
    // Start point (left side)
    final startX = size.width * 0.25;
    final startY = size.height * 0.5;
    // Middle point (bottom of check)
    final midX = size.width * 0.42;
    final midY = size.height * 0.65;
    // End point (top right)
    final endX = size.width * 0.75;
    final endY = size.height * 0.35;
    
    path.moveTo(startX, startY);
    
    if (progress < 0.5) {
      // First half: draw downward stroke to middle point
      final currentProgress = progress * 2;
      final currentX = startX + (midX - startX) * currentProgress;
      final currentY = startY + (midY - startY) * currentProgress;
      path.lineTo(currentX, currentY);
    } else {
      // Second half: complete first stroke and draw upward stroke
      path.lineTo(midX, midY);
      
      final currentProgress = (progress - 0.5) * 2;
      final currentX = midX + (endX - midX) * currentProgress;
      final currentY = midY + (endY - midY) * currentProgress;
      path.lineTo(currentX, currentY);
    }
    
    // Draw main check mark
    canvas.drawPath(path, paint);
    
    // Add subtle glow effect with thicker, semi-transparent stroke
    paint.strokeWidth = 10;
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) => 
      oldDelegate.progress != progress;
}
