import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../services/data_service.dart'; 
import '../utils/pdf_generator.dart';

/// DetailsScreen displays comprehensive information about a security alert
/// Features include CCTV feed with privacy controls, AI analysis, and resolution management
class DetailsScreen extends StatefulWidget {
  /// The alert model containing all incident details
  final AlertModel alert;

  const DetailsScreen({super.key, required this.alert});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  /// Controls whether the CCTV feed is visible (privacy override)
  bool _authorizedOverride = false;
  
  /// Flag indicating if the alert is currently being resolved
  bool _isResolving = false;
  
  /// Animation controller for screen entrance fade effect
  late AnimationController _animationController;
  
  /// Fade animation for smooth screen appearance
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade-in animation for screen entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // Clean up animation controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  /// Returns the appropriate color based on alert severity level
  /// HIGH: Red, MEDIUM: Orange, LOW: Green
  Color _getSeverityColor() {
    switch (widget.alert.severity.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFFF6B6B);
      case 'MEDIUM':
        return const Color(0xFFFF8E53);
      case 'LOW':
        return const Color(0xFF9CCC65);
      default:
        return const Color(0xFFFF8E53);
    }
  }

  /// Handles the alert resolution process with confirmation dialog
  /// Updates the database and navigates back with success notification
  Future<void> _resolveAlert() async {
    // Show confirmation dialog to prevent accidental resolution
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.green.withOpacity(0.3), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              'Resolve Alert?',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to mark this alert as resolved? This action will move it to the resolved history.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Resolve',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Exit if user cancelled the operation
    if (confirmed != true) {
      return;
    }

    // Set loading state
    setState(() => _isResolving = true);

    try {
      // Update alert status in database via DataService
      await DataService.resolveAlert(widget.alert.id);

      if (mounted) {
        // Show success notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Alert Resolved Successfully',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Moved to resolved history',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Brief delay to allow user to see the success message
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Navigate back with result=true to notify parent screen to refresh
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // Handle errors and show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    final isResolved = widget.alert.resolved;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      
      // App bar with status indicator
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'INCIDENT DETAILS',
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // Status indicator badge (ACTIVE/RESOLVED)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isResolved
                  ? Colors.green.withOpacity(0.2)
                  : severityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isResolved ? Colors.green : severityColor,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isResolved ? Icons.check_circle : Icons.warning_amber,
                  size: 14,
                  color: isResolved ? Colors.green : severityColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isResolved ? 'RESOLVED' : 'ACTIVE',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isResolved ? Colors.green : severityColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with alert type, severity, and metadata
              _buildHeaderSection(severityColor, isResolved),

              // CCTV feed with privacy controls
              _buildCCTVFeedSection(),

              // AI analysis section with confidence score
              _buildAIAnalysisSection(),

              // Additional details section (optional fields)
              _buildAdditionalDetailsSection(),

              // Resolution notes (only shown if resolved)
              if (isResolved && widget.alert.resolutionNotes != null)
                _buildResolutionNotesSection(),

              // Bottom padding for floating action buttons
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      
      // Floating action buttons for resolve and PDF generation
      floatingActionButton: _buildFloatingActionButtons(isResolved),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Builds the header section with alert type, severity badges, and metadata
  Widget _buildHeaderSection(Color severityColor, bool isResolved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isResolved ? Colors.green : severityColor).withOpacity(0.3),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: isResolved ? Colors.green : severityColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert type icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isResolved ? Colors.green : severityColor)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isResolved ? Colors.green : severityColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  widget.alert.getTypeIcon(),
                  color: isResolved ? Colors.green : severityColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alert.type.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Show resolution timestamp if resolved
                    if (isResolved && widget.alert.resolvedAt != null)
                      Text(
                        'Resolved ${DateFormat('dd MMM yyyy, HH:mm').format(widget.alert.resolvedAt!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.green.shade300,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Metadata badges (severity, location, time, floor)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Severity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: severityColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  widget.alert.severity.toUpperCase(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Location badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.alert.location,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(widget.alert.timestamp),
                      style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Floor badge (optional)
              if (widget.alert.floor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.alert.floor} Floor',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade300),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the CCTV feed section with privacy blur and authorization toggle
  Widget _buildCCTVFeedSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _authorizedOverride ? Colors.green : Colors.red,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_authorizedOverride ? Colors.green : Colors.red)
                .withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // CCTV header with camera info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Recording indicator (red dot)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CCTV - ${widget.alert.location}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Detection source badge
                if (widget.alert.detectedBy != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.alert.detectedBy!,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // CCTV image with privacy blur overlay
          Stack(
            children: [
              // Base image
              Image.network(
                widget.alert.imageUrl ??
                    'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=800',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.videocam_off, size: 48, color: Colors.white24),
                    ),
                  );
                },
              ),
              
              // Privacy blur overlay (shown when not authorized)
              if (!_authorizedOverride)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                size: 40,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'PRIVACY MODE',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enable override to view',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Authorization toggle switch
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: SwitchListTile(
              value: _authorizedOverride,
              onChanged: (value) {
                setState(() {
                  _authorizedOverride = value;
                });
              },
              title: Text(
                'Authorized Override',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                _authorizedOverride ? 'Clear view enabled' : 'Privacy protected',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: _authorizedOverride ? Colors.green : Colors.orange,
                ),
              ),
              activeColor: Colors.green,
              activeTrackColor: Colors.green.withOpacity(0.5),
              secondary: Icon(
                _authorizedOverride ? Icons.visibility : Icons.visibility_off,
                color: _authorizedOverride ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the AI analysis section with confidence score and detection details
  Widget _buildAIAnalysisSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with confidence score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'AI ANALYSIS',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              
              // Confidence score badge
              if (widget.alert.confidenceScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${(widget.alert.confidenceScore! * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // AI-generated details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              widget.alert.details,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Detection timestamp
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'Detected: ${DateFormat('dd MMM yyyy, HH:mm:ss').format(widget.alert.timestamp)}',
                style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
          
          // Response time (optional)
          if (widget.alert.responseTime != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.timer, size: 12, color: Colors.orange.shade300),
                const SizedBox(width: 6),
                Text(
                  'Response Time: ${widget.alert.responseTime}s',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Colors.orange.shade300,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the additional details section (description, tags, assignment)
  /// Only shown if at least one optional field is present
  Widget _buildAdditionalDetailsSection() {
    // Hide section if no additional details available
    if (widget.alert.description == null &&
        widget.alert.tags == null &&
        widget.alert.assignedTo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              Text(
                'ADDITIONAL DETAILS',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description text
          if (widget.alert.description != null) ...[
            Text(
              widget.alert.description!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Tags as chips
          if (widget.alert.tags != null && widget.alert.tags!.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.alert.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.purple.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          
          // Assignment information
          if (widget.alert.assignedTo != null) ...[
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.cyan.shade300),
                const SizedBox(width: 8),
                Text(
                  'Assigned to: ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  widget.alert.assignedTo!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.cyan.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the resolution notes section (only shown for resolved alerts)
  Widget _buildResolutionNotesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Text(
                'RESOLUTION NOTES',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
                    // Resolution notes text
          Text(
            widget.alert.resolutionNotes!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.green.shade200,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the floating action buttons based on alert resolution status
  /// Resolved alerts: Show only PDF generation button
  /// Active alerts: Show both resolve and PDF generation buttons
  Widget _buildFloatingActionButtons(bool isResolved) {
    if (isResolved) {
      // Only show PDF generation button for resolved alerts
      return FloatingActionButton.extended(
        onPressed: () => PDFGenerator.generateReport(widget.alert),
        backgroundColor: Colors.red,
        heroTag: 'pdf',
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
        label: Text(
          'Generate Report',
          style: GoogleFonts.rajdhani(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Show both resolve and PDF buttons for active alerts
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary action: Resolve alert button
        FloatingActionButton.extended(
          onPressed: _isResolving ? null : _resolveAlert,
          backgroundColor: _isResolving ? Colors.grey : Colors.green,
          heroTag: 'resolve',
          icon: _isResolving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_circle, color: Colors.white, size: 20),
          label: Text(
            _isResolving ? 'Resolving...' : 'Mark as Resolved',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Secondary action: Generate PDF report button
        FloatingActionButton.extended(
          onPressed: () => PDFGenerator.generateReport(widget.alert),
          backgroundColor: Colors.red,
          heroTag: 'pdf',
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
          label: Text(
            'Generate Report',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

