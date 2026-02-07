import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'firebase_setup_screen.dart';

/// AdminSettingsScreen provides a comprehensive settings interface for administrators
/// Features include notification controls, detection sensitivity adjustment, system info, and logout
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  /// Toggle for push notification alerts
  bool _notificationsEnabled = true;
  
  /// Toggle for sound alerts on critical events
  bool _soundEnabled = true;
  
  /// Toggle for automatic incident recording
  bool _autoRecordEnabled = true;
  
  /// Current confirmed AI detection sensitivity level (0.0 to 1.0)
  double _sensitivityLevel = 0.7;
  
  /// Temporary sensitivity value while user is adjusting slider
  /// Used to show preview before confirmation
  double _tempSensitivityLevel = 0.7;
  
  /// Animation controller for pulsing ADMIN badge effect
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Initialize pulse animation for admin badge with 1.5 second cycle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Clean up animation controller to prevent memory leaks
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dark gradient background matching app theme
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              
              // Scrollable content area with all settings sections
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Admin profile information card
                    _buildProfileCard(),
                    const SizedBox(height: 16),

                    // Notification preferences section
                    _buildSettingsCard(
                      'Notifications',
                      Icons.notifications_outlined,
                      [
                        _buildSwitchTile(
                          'Push Notifications',
                          'Receive alerts on your device',
                          _notificationsEnabled,
                          (value) => setState(() => _notificationsEnabled = value),
                        ),
                        _buildSwitchTile(
                          'Sound Alerts',
                          'Play sound for critical alerts',
                          _soundEnabled,
                          (value) => setState(() => _soundEnabled = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // AI detection configuration section
                    _buildSettingsCard(
                      'Detection',
                      Icons.radar,
                      [
                        _buildSwitchTile(
                          'Auto Recording',
                          'Automatically record incidents',
                          _autoRecordEnabled,
                          (value) => setState(() => _autoRecordEnabled = value),
                        ),
                        _buildSliderTile(
                          'Sensitivity Level',
                          'Adjust AI detection sensitivity',
                          _sensitivityLevel,
                          (value) => setState(() => _sensitivityLevel = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // System version and status information
                    _buildSystemInfoCard(),
                    const SizedBox(height: 16),

                    // Logout action button
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top header bar with logo, title, dev tools button, and animated admin badge
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // App logo scaled up for prominence
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
          
          // Gradient text for SETTINGS title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFFE66D),
              ],
            ).createShader(bounds),
            child: Text(
              'SETTINGS',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          
          const Spacer(),

          // Developer tools access button
          // Navigates to Firebase configuration screen
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirebaseSetupScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD93D).withOpacity(0.2),
                    const Color(0xFFFF8E53).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD93D).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.developer_mode,
                    size: 12,
                    color: const Color(0xFFFFD93D),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'DEV',
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      color: const Color(0xFFFFD93D),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Animated admin badge with pulsing glow effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Calculate opacity based on animation value for pulsing effect
              final opacity = 0.3 + (_pulseController.value * 0.7);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B6B).withOpacity(0.2 * opacity),
                      const Color(0xFFFF8E53).withOpacity(0.1 * opacity),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(opacity),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3 * opacity),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 12,
                      color: const Color(0xFFFF6B6B).withOpacity(opacity),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ADMIN',
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        color: const Color(0xFFFF6B6B).withOpacity(opacity),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the admin profile card displaying user information and role
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Gradient background with red/purple theme
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.15),
            const Color(0xFF6C5CE7).withOpacity(0.1),
            Colors.black.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular avatar with gradient border
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.3),
                  const Color(0xFFFF6B6B).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              // Gradient person icon
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User information column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name
                Text(
                  'Monash Admin User',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Email address with icon
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'admin@safevision.com',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Administrator role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00FF88).withOpacity(0.2),
                        const Color(0xFF4ECDC4).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 12,
                        color: const Color(0xFF00FF88),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ADMINISTRATOR',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: const Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a settings section card with title, icon, and child widgets
  /// Used for grouping related settings together
  Widget _buildSettingsCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4ECDC4).withOpacity(0.1),
            const Color(0xFF6C5CE7).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Child settings widgets
          ...children,
        ],
      ),
    );
  }

  /// Builds a toggle switch setting row with title, subtitle, and switch control
  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Text labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle switch control
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4ECDC4),
              activeTrackColor: const Color(0xFF4ECDC4).withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows confirmation dialog when sensitivity level is changed significantly
  /// Displays current and new values with visual comparison
  Future<void> _confirmSensitivityChange(double newValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        // Dialog header with warning icon
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withOpacity(0.2),
                    const Color(0xFFFF8E53).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFFF6B6B),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirm Change',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        // Dialog content showing before/after comparison
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change AI Detection Sensitivity?',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // Before and after value comparison
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Current level display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Level',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4ECDC4),
                          ),
                        ),
                        child: Text(
                          '${(_sensitivityLevel * 100).toInt()}%',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4ECDC4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Arrow separator
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white60,
                    size: 24,
                  ),
                  // New level display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'New Level',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B6B).withOpacity(0.2),
                              const Color(0xFFFF8E53).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                        child: Text(
                          '${(newValue * 100).toInt()}%',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Information notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD93D).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFFD93D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will affect how the AI detects security threats.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Dialog action buttons
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    // Apply change if confirmed
    if (confirmed == true) {
      setState(() {
        _sensitivityLevel = newValue;
      });
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF00FF88),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sensitivity updated to ${(newValue * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1a1a2e),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF00FF88).withOpacity(0.3),
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Reset to original value if cancelled
      setState(() {
        _tempSensitivityLevel = _sensitivityLevel;
      });
    }
  }

  /// Builds a slider control for adjusting sensitivity with confirmation requirement
  /// Shows current value and requires confirmation for significant changes
  Widget _buildSliderTile(String title, String subtitle, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and current value display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: const Color(0xFFFF6B6B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current percentage value badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4ECDC4).withOpacity(0.2),
                        const Color(0xFF6C5CE7).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4),
                    ),
                  ),
                  child: Text(
                    '${(_tempSensitivityLevel * 100).toInt()}%',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ECDC4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Slider control
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF4ECDC4),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: const Color(0xFF4ECDC4),
                overlayColor: const Color(0xFF4ECDC4).withOpacity(0.3),
                trackHeight: 4,
              ),
              child: Slider(
                value: _tempSensitivityLevel,
                // Update temporary value while dragging
                onChanged: (newValue) {
                  setState(() {
                    _tempSensitivityLevel = newValue;
                  });
                },
                // Show confirmation when user releases slider
                onChangeEnd: (newValue) {
                  // Only show confirmation for changes greater than 5%
                  if ((newValue - _sensitivityLevel).abs() > 0.05) {
                    _confirmSensitivityChange(newValue);
                  } else {
                    // Small change, no confirmation needed
                    setState(() {
                      _sensitivityLevel = newValue;
                    });
                  }
                },
                min: 0,
                max: 1,
              ),
            ),
            
            // Warning notice about confirmation requirement
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD93D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD93D).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: const Color(0xFFFFD93D),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changes require confirmation',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds system information card displaying version, status, and statistics
  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.1),
            const Color(0xFF4ECDC4).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                                        colors: [Color(0xFF6C5CE7), Color(0xFF4ECDC4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'System Information',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Information rows container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Version', '2.1.0'),
                _buildInfoRow('Last Updated', 'Jan 15, 2026'),
                _buildInfoRow('Active Cameras', '24'),
                _buildInfoRow('System Status', 'Operational', const Color(0xFF00FF88)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single information row with label and value
  /// Optional valueColor parameter adds colored indicator dot for status values
  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label text
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          // Value with optional status indicator
          Row(
            children: [
              // Colored dot indicator for status (if color provided)
              if (valueColor != null)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: valueColor,
                    boxShadow: [
                      BoxShadow(
                        color: valueColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              // Value text
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the logout button with gradient styling and confirmation dialog
  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Red to orange gradient for logout action
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
        onPressed: () {
          // Show confirmation dialog before logging out
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              actions: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Confirm logout button
                ElevatedButton(
                  onPressed: () {
                    // Close dialog
                    Navigator.pop(context);
                    // Navigate to login screen and remove all previous routes
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
