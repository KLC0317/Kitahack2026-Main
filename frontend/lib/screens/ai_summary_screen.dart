import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../services/gemini_service.dart';
import '../models/alert_model.dart';
import 'details_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// AISummaryScreen displays AI-powered security analysis and alert history
/// Features two main tabs: AI Analysis (with Gemini-powered insights) and History (ongoing/resolved alerts)
class AISummaryScreen extends StatefulWidget {
  const AISummaryScreen({super.key});

  @override
  State<AISummaryScreen> createState() => _AISummaryScreenState();
}

class _AISummaryScreenState extends State<AISummaryScreen>
    with TickerProviderStateMixin {
  /// Animation controller for shimmer loading effect
  late AnimationController _shimmerController;
  
  /// Animation controller for pulsing Gemini badge
  late AnimationController _pulseController;
  
  /// Animation controller for rotating refresh icon
  late AnimationController _rotateController;
  
  /// Tab controller for main tabs (AI Analysis / History)
  late TabController _mainTabController;
  
  /// Tab controller for history sub-tabs (Ongoing / Resolved)
  late TabController _historyTabController;
  
  /// Flag indicating if AI summary is currently being generated
  bool _isGeneratingSummary = false;
  
  /// Stores the AI-generated analysis data including summary and recommendations
  Map<String, dynamic> _aiAnalysis = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controllers
    _mainTabController = TabController(length: 2, vsync: this);
    _historyTabController = TabController(length: 2, vsync: this);
    
    // Initialize shimmer animation for loading states
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Initialize pulse animation for Gemini badge
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize rotation animation for refresh button
    _rotateController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Generate initial AI summary on screen load
    _generateAISummary();
  }

  @override
  void dispose() {
    // Clean up animation controllers to prevent memory leaks
    _shimmerController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _mainTabController.dispose();
    _historyTabController.dispose();
    super.dispose();
  }

  /// Generates AI-powered security analysis using Gemini service
  /// Fetches current alerts and processes them through AI for insights
  Future<void> _generateAISummary() async {
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      // Fetch latest alerts from data service
      final alertsSnapshot = await DataService.getAlertsStream().first;
      
      // Generate AI analysis using Gemini service
      final analysis = await GeminiService.generateSecurityAnalysis(alertsSnapshot);
      
      setState(() {
        _aiAnalysis = analysis;
        _isGeneratingSummary = false;
      });
    } catch (e) {
      // Handle errors gracefully with fallback message
      setState(() {
        _isGeneratingSummary = false;
        _aiAnalysis = {
          'summary': 'Error generating summary. Please try again.',
          'recommendations': []
        };
      });
    }
  }

  /// Navigates to alert details screen with smooth transition animation
  /// Returns true if alert was modified (resolved/updated)
  Future<void> _navigateToDetails(AlertModel alert) async {
    final result = await Navigator.push(
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
    
    // Refresh UI if alert was modified
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

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
              _buildHeader(isSmallScreen),
              _buildMainTabBar(isSmallScreen),
              
              // Main content area with tab views
              Expanded(
                child: TabBarView(
                  controller: _mainTabController,
                  children: [
                    // AI Summary Tab - displays analysis and recommendations
                    StreamBuilder<List<AlertModel>>(
                      stream: DataService.getAlertsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        
                        if (!snapshot.hasData) {
                          return _buildLoadingScreen();
                        }
                        
                        final alerts = snapshot.data!;
                        return _buildSummaryView(alerts, isSmallScreen);
                      },
                    ),
                    
                    // History Tab - displays ongoing and resolved alerts
                    _buildHistoryTabView(isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds loading screen with spinner and message
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFF4ECDC4),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading AI insights...',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error state display with error message
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header bar with logo, title, and animated Gemini badge
  Widget _buildHeader(bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // App logo scaled for prominence
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
          
          // Gradient text for screen title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFFE66D),
              ],
            ).createShader(bounds),
            child: Text(
              'AI INSIGHTS',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Animated Gemini AI badge with pulsing effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Calculate opacity for pulsing animation
              final opacity = 0.3 + (_pulseController.value * 0.7);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4ECDC4).withOpacity(0.2 * opacity),
                      const Color(0xFF6C5CE7).withOpacity(0.1 * opacity),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(opacity),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.3 * opacity),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: const Color(0xFF4ECDC4).withOpacity(opacity),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'GEMINI',
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        color: const Color(0xFF4ECDC4).withOpacity(opacity),
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

  /// Builds the main tab bar for switching between AI Analysis and History
  Widget _buildMainTabBar(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D2D),
            const Color(0xFF1a1a2e),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TabBar(
        controller: _mainTabController,
        // Gradient indicator for selected tab
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.rajdhani(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Text('AI ANALYSIS'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 18),
                const SizedBox(width: 8),
                Text('HISTORY'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the AI summary view with stats, analysis, and recommendations
  Widget _buildSummaryView(List<AlertModel> alerts, bool isSmallScreen) {
    // Calculate alert counts by severity
    final highAlerts = alerts.where((a) => a.severity == 'HIGH').length;
    final mediumAlerts = alerts.where((a) => a.severity == 'MEDIUM').length;
    final lowAlerts = alerts.where((a) => a.severity == 'LOW').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics overview card
          _buildStatsCard(alerts, highAlerts, mediumAlerts, lowAlerts, isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // AI-generated summary card
          _buildAISummaryCard(isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // AI-generated recommendations
          _buildRecommendations(isSmallScreen),
        ],
      ),
    );
  }

  /// Builds the statistics card showing alert counts and system metrics
  Widget _buildStatsCard(List alerts, int highAlerts, int mediumAlerts,
      int lowAlerts, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
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
      child: Column(
        children: [
          Row(
            children: [
              // Circular total events counter
              Container(
                width: isSmallScreen ? 80 : 90,
                height: isSmallScreen ? 80 : 90,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total count with gradient text
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                        ).createShader(bounds),
                        child: Text(
                          '${alerts.length}',
                          style: GoogleFonts.orbitron(
                            fontSize: isSmallScreen ? 32 : 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EVENTS',
                        style: GoogleFonts.rajdhani(
                          fontSize: isSmallScreen ? 8 : 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Severity breakdown bars
              Expanded(
                child: Column(
                  children: [
                    _buildCompactSeverityBar(
                      'CRITICAL',
                      highAlerts,
                      alerts.length,
                      const Color(0xFFFF6B6B),
                      Icons.warning_rounded,
                      isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    _buildCompactSeverityBar(
                      'MEDIUM',
                      mediumAlerts,
                      alerts.length,
                      const Color(0xFFFF8E53),
                      Icons.info_rounded,
                      isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    _buildCompactSeverityBar(
                      'LOW',
                      lowAlerts,
                      alerts.length,
                      const Color(0xFF00FF88),
                      Icons.check_circle_rounded,
                      isSmallScreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 14),
          
          // System performance metrics
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12,
              vertical: isSmallScreen ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMicroStat(
                  '98.3%',
                  'Accuracy',
                  Icons.verified,
                  const Color(0xFF00FF88),
                  isSmallScreen,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.1),
                ),
                _buildMicroStat(
                  '2.1s',
                  'Response',
                  Icons.speed,
                  const Color(0xFF4ECDC4),
                  isSmallScreen,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.1),
                ),
                _buildMicroStat(
                  '99.9%',
                  'Uptime',
                  Icons.cloud_done,
                  const Color(0xFF6C5CE7),
                  isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a compact severity bar showing count and percentage
  Widget _buildCompactSeverityBar(String label, int count, int total,
      Color color, IconData icon, bool isSmallScreen) {
    // Calculate percentage for progress bar
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Row(
      children: [
        // Severity icon
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: isSmallScreen ? 14 : 16,
          ),
        ),
        const SizedBox(width: 8),
        
        // Label, count, and progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label and count row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      fontSize: isSmallScreen ? 10 : 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '$count',
                    style: GoogleFonts.orbitron(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Background track
                    Container(
                      height: isSmallScreen ? 6 : 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Filled portion
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: isSmallScreen ? 6 : 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a micro statistic display with icon, value, and label
  Widget _buildMicroStat(String value, String label, IconData icon,
      Color color, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: isSmallScreen ? 16 : 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 8 : 9,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  /// Builds the AI summary card with Gemini-generated analysis
  /// Includes refresh button to regenerate analysis
  Widget _buildAISummaryCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          // Header with title and refresh button
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI ANALYSIS',
                      style: GoogleFonts.orbitron(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Powered by Gemini',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 8 : 9,
                        color: Colors.white60,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button with tooltip
              Tooltip(
                message: 'Refresh Analysis & Recommendations',
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF4ECDC4).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _isGeneratingSummary ? null : _generateAISummary,
                    icon: AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, child) {
                        // Rotate icon while generating
                        return Transform.rotate(
                          angle: _isGeneratingSummary
                              ? _rotateController.value * 2 * pi
                              : 0,
                          child: Icon(
                            Icons.refresh_rounded,
                            color: _isGeneratingSummary 
                                ? const Color(0xFF4ECDC4).withOpacity(0.5)
                                : const Color(0xFF4ECDC4),
                          ),
                        );
                      },
                    ),
                    iconSize: isSmallScreen ? 20 : 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          // Summary content area
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isGeneratingSummary
                ? _buildLoadingState(isSmallScreen)
                : _buildSummaryParagraphs(isSmallScreen),
          ),
        ],
      ),
    );
  }

  /// Builds the summary content as formatted paragraphs with bullet points
  Widget _buildSummaryParagraphs(bool isSmallScreen) {
    final summaryList = _aiAnalysis['summary'];
    
    if (summaryList == null) {
      return Text(
        'No analysis available',
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 12 : 13,
          color: Colors.white.withOpacity(0.9),
          height: 1.6,
        ),
      );
    }

    // Handle both List and String formats from AI response
    List<String> paragraphs;
    if (summaryList is List) {
      paragraphs = summaryList.map((e) => e.toString()).toList();
    } else if (summaryList is String) {
      paragraphs = [summaryList];
    } else {
      paragraphs = ['No analysis available'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraph = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < paragraphs.length - 1 ? (isSmallScreen ? 10 : 12) : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bullet point indicator
              Container(
                margin: const EdgeInsets.only(top: 4, right: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4ECDC4),
                      const Color(0xFF6C5CE7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Paragraph text
              Expanded(
                child: Text(
                  paragraph,
                  style: GoogleFonts.inter(
                                        fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds the recommendations section with AI-generated action items
  Widget _buildRecommendations(bool isSmallScreen) {
    final recommendations = _aiAnalysis['recommendations'] as List<dynamic>? ?? [];
    
    // Hide section if no recommendations and not loading
    if (recommendations.isEmpty && !_isGeneratingSummary) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with count badge
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: isSmallScreen ? 10 : 12),
          child: Row(
            children: [
              // Lightbulb icon container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD93D).withOpacity(0.2),
                      const Color(0xFFFF8E53).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD93D).withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: const Color(0xFFFFD93D),
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RECOMMENDATIONS',
                      style: GoogleFonts.orbitron(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'AI-Generated Actions',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 8 : 9,
                        color: Colors.white60,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                  vertical: isSmallScreen ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD93D).withOpacity(0.2),
                      const Color(0xFFFF8E53).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD93D).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '${recommendations.length}',
                  style: GoogleFonts.orbitron(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD93D),
                  ),
                ),
              ),
            ],
          ),
        ),
        // List of recommendation cards
        ...recommendations.map((rec) {
          final priority = rec['priority'] as String? ?? 'MEDIUM';
          final icon = _getRecommendationIcon(rec['icon'] as String? ?? 'security');
          final color = _getPriorityColor(priority);
          
          return Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
            child: _buildRecommendationCard(
              rec['title'] as String? ?? 'Recommendation',
              rec['description'] as String? ?? 'No description',
              icon,
              color,
              priority,
              isSmallScreen,
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Builds the loading state with animated shimmer effect
  Widget _buildLoadingState(bool isSmallScreen) {
    return Column(
      children: [
        // Loading header with rotating icon
        Row(
          children: [
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * pi,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF6C5CE7)],
                    ).createShader(bounds),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Expanded(
              child: Text(
                'Analyzing security data with Gemini AI...',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        // Shimmer loading bars
        ...List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  height: isSmallScreen ? 8 : 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      stops: [
                        max(0, _shimmerController.value - 0.3),
                        _shimmerController.value,
                        min(1, _shimmerController.value + 0.3),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  /// Maps icon name string to Flutter IconData
  IconData _getRecommendationIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'patrol':
        return Icons.directions_walk;
      case 'camera':
        return Icons.videocam;
      case 'maintenance':
        return Icons.build_circle;
      case 'alert':
        return Icons.warning_amber;
      case 'security':
        return Icons.security;
      default:
        return Icons.info;
    }
  }

  /// Returns color based on priority level
  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFFF6B6B);
      case 'MEDIUM':
        return const Color(0xFFFF8E53);
      case 'LOW':
        return const Color(0xFF00FF88);
      default:
        return const Color(0xFF4ECDC4);
    }
  }

  /// Builds a single recommendation card with icon, title, description, and priority badge
  Widget _buildRecommendationCard(String title, String description,
      IconData icon, Color color, String priority, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 20 : 22),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          // Title, description, and priority badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Priority badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.rajdhani(
                          fontSize: isSmallScreen ? 8 : 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 3 : 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.white60,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
        ],
      ),
    );
  }

  /// Builds the history tab view with sub-tabs for ongoing and resolved alerts
  Widget _buildHistoryTabView(bool isSmallScreen) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // History sub-tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.4),
                const Color(0xFF1a1a2e).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: StreamBuilder<List<AlertModel>>(
            stream: DataService.getAlertsStream(),
            builder: (context, snapshot) {
              final allAlerts = snapshot.data ?? [];
              final ongoingCount = allAlerts.where((a) => !a.resolved).length;
              final resolvedCount = allAlerts.where((a) => a.resolved).length;

              return TabBar(
                controller: _historyTabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                unselectedLabelStyle: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                tabs: [
                  // Ongoing tab with count
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('ONGOING'),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$ongoingCount',
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Resolved tab with count
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16),
                        const SizedBox(width: 6),
                        Text('RESOLVED'),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$resolvedCount',
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Tab view content
        Expanded(
          child: TabBarView(
            controller: _historyTabController,
            children: [
              // Ongoing alerts stream
              StreamBuilder<List<AlertModel>>(
                stream: DataService.getOngoingAlertsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFFFF6B6B),
                        strokeWidth: 3,
                      ),
                    );
                  }
                  
                  final ongoingAlerts = snapshot.data!;
                  return _buildHistoryList(
                    ongoingAlerts,
                    isOngoing: true,
                    isSmallScreen: isSmallScreen,
                  );
                },
              ),
              
              // Resolved alerts stream
              StreamBuilder<List<AlertModel>>(
                stream: DataService.getResolvedAlertsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 3,
                      ),
                    );
                  }
                  
                  final resolvedAlerts = snapshot.data!;
                  return _buildHistoryList(
                    resolvedAlerts,
                    isOngoing: false,
                    isSmallScreen: isSmallScreen,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the history list grouped by date
  /// Shows empty state if no alerts available
  Widget _buildHistoryList(List<AlertModel> alerts, {required bool isOngoing, required bool isSmallScreen}) {
    // Show empty state if no alerts
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    (isOngoing ? const Color(0xFFFF6B6B) : const Color(0xFF00FF88)).withOpacity(0.2),
                    (isOngoing ? const Color(0xFFFF6B6B) : const Color(0xFF00FF88)).withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                isOngoing ? Icons.check_circle_outline : Icons.history,
                size: 64,
                color: isOngoing ? const Color(0xFFFF6B6B).withOpacity(0.5) : const Color(0xFF00FF88).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isOngoing ? 'No Ongoing Alerts' : 'No Resolved Alerts',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOngoing
                  ? 'All clear! No active incidents detected.'
                  : 'No alerts have been resolved yet.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group alerts by date
    Map<String, List<AlertModel>> groupedAlerts = {};
    for (var alert in alerts) {
      final dateKey = DateFormat('MMM dd, yyyy').format(alert.timestamp);
      if (!groupedAlerts.containsKey(dateKey)) {
        groupedAlerts[dateKey] = [];
      }
      groupedAlerts[dateKey]!.add(alert);
    }

    // Build list with date headers
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      itemCount: groupedAlerts.length,
      itemBuilder: (context, index) {
        final dateKey = groupedAlerts.keys.elementAt(index);
        final dayAlerts = groupedAlerts[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOngoing
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                            : [const Color(0xFF00FF88), const Color(0xFF4ECDC4)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isOngoing ? const Color(0xFFFF6B6B) : const Color(0xFF00FF88)).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateKey,
                          style: GoogleFonts.orbitron(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${dayAlerts.length} ${dayAlerts.length == 1 ? 'event' : 'events'}',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 9 : 10,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Event count badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: (isOngoing ? const Color(0xFFFF6B6B) : const Color(0xFF00FF88))
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isOngoing ? const Color(0xFFFF6B6B) : const Color(0xFF00FF88))
                            .withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '${dayAlerts.length}',
                      style: GoogleFonts.orbitron(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w900,
                        color: isOngoing ? const Color(0xFFFF6B6B) : const Color(0xFF00FF88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Alert cards for this date
            ...dayAlerts
                .map((alert) => _buildClickableHistoryCard(alert, isOngoing, isSmallScreen))
                .toList(),
            SizedBox(height: isSmallScreen ? 8 : 10),
          ],
        );
      },
    );
  }

  /// Builds a clickable history card for an individual alert
  /// Navigates to details screen on tap
  Widget _buildClickableHistoryCard(AlertModel alert, bool isOngoing, bool isSmallScreen) {
    // Determine color and icon based on severity and status
    Color severityColor;

    if (isOngoing) {
      switch (alert.severity.toUpperCase()) {
        case 'HIGH':
          severityColor = const Color(0xFFFF6B6B);
          break;
        case 'MEDIUM':
          severityColor = const Color(0xFFFF8E53);
          break;
        default:
          severityColor = const Color(0xFF00FF88);
      }
    } else {
      severityColor = const Color(0xFF00FF88);
    }

    return GestureDetector(
      onTap: () => _navigateToDetails(alert),
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D2D),
              const Color(0xFF1a1a2e),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOngoing
                ? severityColor.withOpacity(0.5)
                : Colors.green.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isOngoing ? severityColor : Colors.green).withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToDetails(alert),
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Left accent bar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isOngoing ? severityColor : Colors.green,
                            (isOngoing ? severityColor : Colors.green).withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Card content
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row with icon, type, location, and status
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                color: (isOngoing ? severityColor : Colors.green).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (isOngoing ? severityColor : Colors.green).withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                alert.getTypeIcon(),
                                color: isOngoing ? severityColor : Colors.green,
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    alert.type.toUpperCase(),
                                    style: GoogleFonts.rajdhani(
                                      fontSize: isSmallScreen ? 14 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: isSmallScreen ? 11 : 12,
                                        color: Colors.white60,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          alert.location,
                                          style: GoogleFonts.inter(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            color: Colors.white60,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: isOngoing
                                    ? severityColor.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOngoing ? severityColor : Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOngoing ? Icons.warning_amber : Icons.check_circle,
                                    size: 12,
                                    color: isOngoing ? severityColor : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOngoing ? alert.severity : 'RESOLVED',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOngoing ? severityColor : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        // Alert details
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Text(
                            alert.details,
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        // Footer with timestamp and arrow
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                                                            color: Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('hh:mm a').format(alert.timestamp),
                              style: GoogleFonts.robotoMono(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Tap to view indicator
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF4ECDC4).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'VIEW',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4ECDC4),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 10,
                                    color: const Color(0xFF4ECDC4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
