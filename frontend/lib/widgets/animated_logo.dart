import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated logo widget with multiple layered animations
/// Features pulsing, rotation, floating, glowing, particles, and shimmer effects
class AnimatedLogo extends StatefulWidget {
  /// Size of the logo widget
  final double size;

  const AnimatedLogo({
    super.key,
    this.size = 140,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation - breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Rotation animation - slow continuous rotation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Float animation - gentle up and down movement
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // Glow animation - pulsing glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Particle animation - orbiting particles
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Shimmer animation - light sweep effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotationController,
        _floatController,
        _glowController,
        _particleController,
        _shimmerController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: widget.size * 1.15,
                      height: widget.size * 1.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),

                  // Counter-rotating ring
                  Transform.rotate(
                    angle: -_rotationAnimation.value * 1.5,
                    child: Container(
                      width: widget.size * 1.25,
                      height: widget.size * 1.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1.5,
                          color: const Color(0xFF3498DB).withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),

                  // Orbiting particles (8 particles around the logo)
                  ...List.generate(8, (index) {
                    final angle = (index / 8) * 2 * math.pi +
                        (_particleController.value * 2 * math.pi);
                    final radius = widget.size * 0.58;
                    final x = math.cos(angle) * radius;
                    final y = math.sin(angle) * radius;

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              const Color(0xFF9B59B6).withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Animated glow layers with multiple colors
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Outer glow - purple
                        BoxShadow(
                          color: const Color(0xFF9B59B6)
                              .withOpacity(0.4 * _glowAnimation.value),
                          blurRadius: 50 * _glowAnimation.value,
                          spreadRadius: 15 * _glowAnimation.value,
                        ),
                        // Middle glow - blue
                        BoxShadow(
                          color: const Color(0xFF3498DB)
                              .withOpacity(0.35 * _glowAnimation.value),
                          blurRadius: 40 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                        // Inner glow - cyan
                        BoxShadow(
                          color: const Color(0xFF1ABC9C)
                              .withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 30 * _glowAnimation.value,
                          spreadRadius: 5 * _glowAnimation.value,
                        ),
                        // Soft white glow
                        BoxShadow(
                          color: Colors.white
                              .withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 25 * _glowAnimation.value,
                          spreadRadius: 3 * _glowAnimation.value,
                        ),
                      ],
                    ),
                  ),

                  // Main logo container with gradient border
                  Container(
                    width: widget.size * 0.85,
                    height: widget.size * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        width: 3,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFE66D).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Logo image with fallback
                        ClipOval(
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: widget.size * 0.85,
                              height: widget.size * 0.85,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon with gradient
                                return Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFF6B6B),
                                        Color(0xFFFF8E53),
                                        Color(0xFFFFE66D),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shield,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Shimmer overlay effect
                        Positioned.fill(
                          child: ClipOval(
                            child: CustomPaint(
                              painter: ShimmerPainter(
                                progress: _shimmerAnimation.value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Inner decorative ring
                  Container(
                    width: widget.size * 0.7,
                    height: widget.size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 1.5,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),

                  // Sparkles at cardinal points (4 sparkles)
                  ...List.generate(4, (index) {
                    final angle = (index * math.pi / 2) +
                        (_rotationAnimation.value * 0.5);
                    final radius = widget.size * 0.48;
                    final x = math.cos(angle) * radius;
                    final y = math.sin(angle) * radius;

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 2,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white
                              .withOpacity(0.8 * _glowAnimation.value),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for creating a shimmer/light sweep effect
class ShimmerPainter extends CustomPainter {
  /// Progress of the shimmer animation (0.0 to 1.0)
  final double progress;

  ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
        stops: [
          math.max(0.0, progress - 0.3),
          progress,
          math.min(1.0, progress + 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
