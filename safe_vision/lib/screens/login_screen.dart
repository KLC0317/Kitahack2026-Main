import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../widgets/animated_logo.dart';
import '../services/auth_service.dart';
import 'login_transition_screen.dart';
import 'main_navigation_screen.dart';

/// LoginScreen provides user authentication with animated background and form validation
/// Features include email/password login, animated mesh gradient background, and smooth transitions
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  /// Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  /// Text editing controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  /// Authentication service instance
  final _authService = AuthService();
  
  /// Loading state flag for login operation
  bool _isLoading = false;
  
  /// Password visibility toggle flag
  bool _obscurePassword = true;
  
  // Animation controllers
  /// Main fade-in animation controller for screen entrance
  late AnimationController _fadeController;
  
  /// Slide animation controller for form entrance
  late AnimationController _slideController;
  
  /// Shake animation controller for error feedback
  late AnimationController _shakeController;
  
  /// Lava/mesh gradient animation controller for background
  late AnimationController _lavaController;
  
  /// Slogan pulsing animation controller
  late AnimationController _sloganController;
  
  /// Fade animation for smooth screen appearance
  late Animation<double> _fadeAnimation;
  
  /// Slide animation for form entrance from bottom
  late Animation<Offset> _slideAnimation;
  
  /// Shake animation for error feedback
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade-in animation (1.2s duration)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Initialize slide animation (1s duration)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Initialize shake animation (500ms duration)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Initialize lava background animation (15s duration, repeating)
    _lavaController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Initialize slogan pulse animation (2s duration, repeating)
    _sloganController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Configure fade animation curve
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Configure slide animation from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Configure shake animation for error feedback
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
    
    // Start entrance animations with slight delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    // Clean up animation controllers to prevent memory leaks
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _lavaController.dispose();
    _sloganController.dispose();
    
    // Clean up text editing controllers
    _emailController.dispose();
    _passwordController.dispose();
    
    super.dispose();
  }

  /// Validates email format using regex pattern
  /// Returns error message if invalid, null if valid
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Standard email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  /// Validates password field is not empty
  /// Returns error message if invalid, null if valid
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    return null;
  }

  /// Handles login form submission and navigation
  /// Validates form, calls auth service, and navigates on success
  Future<void> _handleLogin() async {
    // Validate form fields
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate network delay for better UX
      await Future.delayed(const Duration(seconds: 1));
      
      // Attempt login via auth service
      final success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      if (success && mounted) {
                // Navigate to transition screen on successful login
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LoginTransitionScreen(
                  onComplete: () {
                    // Navigate to main navigation screen after transition completes
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const MainNavigationScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                  },
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else if (mounted) {
        // Show error feedback on failed login
        // Trigger shake animation
        _shakeController.forward().then((_) => _shakeController.reverse());
        
        // Display error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invalid email or password',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated mesh gradient background
          AnimatedBuilder(
            animation: _lavaController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: AnimatedMeshGradientPainter(
                  progress: _lavaController.value,
                ),
              );
            },
          ),
          
          // Gradient overlay for improved text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Main scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24.0 : 32.0,
                  vertical: 20,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        // Apply shake animation on error
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated app logo
                          const AnimatedLogo(size: 120),
                          
                          const SizedBox(height: 24),
                          
                          // App title with gradient shader
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFF6B6B),
                                Color(0xFFFFE66D),
                                Color(0xFFFF6B6B),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'SAFE VISION',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 38 : 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Animated slogan with pulsing effect
                          AnimatedBuilder(
                            animation: _sloganController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_sloganController.value * 0.05),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFF6B6B).withOpacity(0.2),
                                        const Color(0xFFFFE66D).withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      width: 2,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6B6B).withOpacity(0.3 * _sloganController.value),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: const Color(0xFFFF6B6B),
                                        size: 16,
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFF6B6B).withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Creating Safe Spaces Together',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.shield,
                                        color: const Color(0xFFFFE66D),
                                        size: 16,
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFFE66D).withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Login form card with glassmorphism effect
                          Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 24 : 28),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.white.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      width: 1.5,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Login header
                                        Text(
                                          'Welcome Back',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 24 : 26,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Email input field
                                        _buildModernTextField(
                                          controller: _emailController,
                                          label: 'Email',
                                          hint: 'you@example.com',
                                          icon: Icons.email_outlined,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: _validateEmail,
                                          isSmallScreen: isSmallScreen,
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Password input field with visibility toggle
                                        _buildModernTextField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          hint: '••••••••',
                                          icon: Icons.lock_outline,
                                          obscureText: _obscurePassword,
                                          validator: _validatePassword,
                                          isSmallScreen: isSmallScreen,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Forgot password link
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              // TODO: Implement forgot password functionality
                                            },
                                            child: Text(
                                              'Forgot Password?',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFFFE66D),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        // Login button with gradient background
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6B6B),
                                                Color(0xFFFF8E53),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                vertical: isSmallScreen ? 16 : 18,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              elevation: 0,
                                              shadowColor: Colors.transparent,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'Sign In',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: isSmallScreen ? 15 : 16,
                                                          fontWeight: FontWeight.w700,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons.arrow_forward_rounded,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Footer with copyright information
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              '© 2026 Team Zestix • Building Better Schools',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a modern styled text field with validation
  /// [controller] - Text editing controller
  /// [label] - Field label text
  /// [hint] - Placeholder hint text
  /// [icon] - Leading icon
  /// [isSmallScreen] - Flag for responsive sizing
  /// [keyboardType] - Keyboard type for input
  /// [obscureText] - Whether to hide text (for passwords)
  /// [validator] - Validation function
  /// [suffixIcon] - Optional trailing icon widget
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isSmallScreen,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: isSmallScreen ? 14 : 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white60,
          fontSize: isSmallScreen ? 13 : 14,
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: const Color(0xFFFFE66D),
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.white30,
          fontSize: isSmallScreen ? 13 : 14,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallScreen ? 16 : 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 2,
            color: Color(0xFFFFE66D),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B6B),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B6B),
            width: 2,
          ),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: const Color(0xFFFF6B6B),
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

/// Custom painter for animated mesh gradient background
/// Creates flowing gradient blobs with connecting lines for visual interest
class AnimatedMeshGradientPainter extends CustomPainter {
  /// Animation progress value (0.0 to 1.0)
  final double progress;

  AnimatedMeshGradientPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base dark gradient background
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0a0a0a),
        const Color(0xFF1a1a2e),
        const Color(0xFF16213e),
      ],
    );
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Define mesh gradient points with positions, sizes, and colors
    final meshPoints = [
      _MeshPoint(0.2, 0.3, 0.3, const Color(0xFFFF6B6B)),
      _MeshPoint(0.8, 0.2, 0.25, const Color(0xFFFF8E53)),
      _MeshPoint(0.5, 0.7, 0.35, const Color(0xFFFFE66D)),
      _MeshPoint(0.1, 0.8, 0.28, const Color(0xFFFF6B6B)),
      _MeshPoint(0.9, 0.6, 0.32, const Color(0xFFFF8E53)),
      _MeshPoint(0.4, 0.1, 0.26, const Color(0xFFFFE66D)),
    ];

    // Draw animated gradient blobs
    for (int i = 0; i < meshPoints.length; i++) {
      final point = meshPoints[i];
      final angle = progress * 2 * math.pi + (i * 0.5);
      
      // Calculate animated position using circular motion
      final x = size.width * point.x + math.cos(angle) * 60;
      final y = size.height * point.y + math.sin(angle * 1.3) * 60;
      
      // Calculate animated size with pulsing effect
      final sizeMultiplier = 1.0 + math.sin(progress * 2 * math.pi + i) * 0.3;
      final radius = size.width * point.radius * sizeMultiplier;
      
      // Create radial gradient for blob
      final gradient = RadialGradient(
        colors: [
          point.color.withOpacity(0.6),
          point.color.withOpacity(0.4),
          point.color.withOpacity(0.2),
          point.color.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: radius),
        )
        ..blendMode = BlendMode.screen;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Draw connecting lines between nearby points
    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.screen;
    
    for (int i = 0; i < meshPoints.length; i++) {
      for (int j = i + 1; j < meshPoints.length; j++) {
        final point1 = meshPoints[i];
        final point2 = meshPoints[j];
        
        final angle1 = progress * 2 * math.pi + (i * 0.5);
        final angle2 = progress * 2 * math.pi + (j * 0.5);
        
        // Calculate animated positions for both points
        final x1 = size.width * point1.x + math.cos(angle1) * 60;
        final y1 = size.height * point1.y + math.sin(angle1 * 1.3) * 60;
        final x2 = size.width * point2.x + math.cos(angle2) * 60;
        final y2 = size.height * point2.y + math.sin(angle2 * 1.3) * 60;
        
        // Calculate distance between points
        final distance = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
        
        // Draw line only if points are close enough (< 300px)
        if (distance < 300) {
          final opacity = (1 - distance / 300) * 0.3;
          linePaint.shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              point1.color.withOpacity(opacity),
              point2.color.withOpacity(opacity),
            ],
          ).createShader(Rect.fromPoints(Offset(x1, y1), Offset(x2, y2)));
          
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(AnimatedMeshGradientPainter oldDelegate) => true;
}

/// Data class representing a mesh gradient point
/// Contains position, size, and color information
class _MeshPoint {
  /// Normalized x position (0.0 to 1.0)
  final double x;
  
  /// Normalized y position (0.0 to 1.0)
  final double y;
  
  /// Normalized radius (0.0 to 1.0)
  final double radius;
  
  /// Gradient color
  final Color color;

  _MeshPoint(this.x, this.y, this.radius, this.color);
}
