import 'package:flutter/material.dart';
import 'digital_twin_screen.dart';
import 'ai_summary_screen.dart';
import 'admin_settings_screen.dart';

/// A stateful widget that provides the main navigation structure for the application.
/// 
/// This screen manages navigation between three main sections:
/// - School Digital Twin Monitor
/// - AI Summary
/// - Admin Settings
/// 
/// Features include:
/// - Bottom navigation bar with animated transitions
/// - Smooth slide and fade animations when switching tabs
/// - Gradient styling with active state indicators
class MainNavigationScreen extends StatefulWidget {
  /// Creates a [MainNavigationScreen] widget.
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

/// State class for [MainNavigationScreen] that manages navigation and animations.
/// 
/// Uses [TickerProviderStateMixin] to provide vsync for the slide animation controller.
class MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  /// The currently selected tab index (0-2).
  int _currentIndex = 0;
  
  /// Animation controller for slide and fade transitions between screens.
  late AnimationController _slideController;

  /// List of screen widgets corresponding to each navigation tab.
  /// 
  /// Index 0: School Digital Twin Screen
  /// Index 1: AI Summary Screen
  /// Index 2: Admin Settings Screen
  final List<Widget> _screens = [
    const SchoolDigitalTwinScreen(),
    const AISummaryScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize slide animation controller with 400ms duration
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    // Set initial value to 1.0 (fully visible, no animation on first load)
    _slideController.value = 1.0;
  }

  @override
  void dispose() {
    // Clean up animation controller to prevent memory leaks
    _slideController.dispose();
    super.dispose();
  }

  /// Changes the active tab to the specified index with animation.
  /// 
  /// Only triggers animation if the new index is different from current.
  /// 
  /// [index] The tab index to navigate to (0-2).
  void changeTab(int index) {
    if (_currentIndex != index) {
      // Start slide animation from beginning
      _slideController.forward(from: 0.0);
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main content area with animated transitions
      body: AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          // Create curved animation for smooth easing
          final slideAnimation = CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
          );
          
          // Apply slide and fade effects during tab transitions
          return Transform.translate(
            // Slide up from 30 pixels below as animation progresses
            offset: Offset(0, 30 * (1 - slideAnimation.value)),
            child: Opacity(
              // Fade in as animation progresses
              opacity: slideAnimation.value,
              child: IndexedStack(
                // Show only the currently selected screen
                index: _currentIndex,
                children: _screens,
              ),
            ),
          );
        },
      ),
      // Custom styled bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Gradient background from dark gray to dark blue
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D2D2D).withOpacity(0.95),
              const Color(0xFF1a1a2e).withOpacity(0.98),
            ],
          ),
          // Elevated shadow effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Monitor/Digital Twin tab
                _buildNavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Monitor',
                  index: 0,
                ),
                // AI Summary tab
                _buildNavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'AI Summary',
                  index: 1,
                ),
                // Settings tab
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an individual navigation item with icon and label.
  /// 
  /// Features:
  /// - Animated container that expands when active
  /// - Gradient background and border for active state
  /// - Icon switches between outlined and filled versions
  /// - Color changes based on active state
  /// 
  /// [icon] The icon to display when inactive (outlined version).
  /// [activeIcon] The icon to display when active (filled version).
  /// [label] The text label displayed below the icon.
  /// [index] The tab index this item represents.
  /// 
  /// Returns a [Widget] representing the navigation item.
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    // Check if this item is currently selected
    final isActive = _currentIndex == index;

    return GestureDetector(
      // Handle tap to change tabs
      onTap: () {
        if (_currentIndex != index) {
          // Start slide animation from beginning
          _slideController.forward(from: 0.0);
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        // Smooth transition for container changes
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Gradient background only when active
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withOpacity(0.3),
                    const Color(0xFFFF8E53).withOpacity(0.3),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          // Border only when active
          border: isActive
              ? Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon - switches between outlined and filled based on active state
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFFFF6B6B) : Colors.white60,
              size: 22,
            ),
            const SizedBox(height: 3),
            // Label text with color and weight changes based on active state
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFFF6B6B) : Colors.white60,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
