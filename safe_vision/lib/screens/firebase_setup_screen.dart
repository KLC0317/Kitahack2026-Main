import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';
import '../services/mock_data_service.dart';
import 'admin_settings_screen.dart';

/// FirebaseSetupScreen provides development tools for testing Firebase integration
/// Features include mock data upload, individual alert testing, and connection verification
class FirebaseSetupScreen extends StatefulWidget {
  const FirebaseSetupScreen({super.key});

  @override
  State<FirebaseSetupScreen> createState() => _FirebaseSetupScreenState();
}

class _FirebaseSetupScreenState extends State<FirebaseSetupScreen> {
  /// Flag indicating if bulk upload operation is in progress
  bool _isUploading = false;
  
  /// Flag indicating if first test alert is being added
  bool _isAddingFirst = false;
  
  /// Flag indicating if second test alert is being added
  bool _isAddingSecond = false;
  
  /// Flag indicating if third test alert is being added
  bool _isAddingThird = false;
  
  /// Status message displayed to user about current operation
  String _statusMessage = '';

  /// Uploads all mock alerts to Firebase in bulk
  /// Shows progress and success/error messages to user
  Future<void> _uploadMockData() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading mock data to Firebase...';
    });

    try {
      // Get mock alerts from MockDataService
      final mockAlerts = MockDataService.getAlerts();
      
      // Upload to Firebase via DataService
      await DataService.uploadMockData(mockAlerts);
      
      setState(() {
        _statusMessage = '✅ Successfully uploaded ${mockAlerts.length} alerts to Firebase!';
      });

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Uploaded ${mockAlerts.length} alerts successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle upload errors
      setState(() {
        _statusMessage = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// Adds a single mock alert by index for testing notifications
  /// [index] - The index of the alert in mock data (0, 1, or 2)
  Future<void> _addAlertByIndex(int index) async {
    // Set appropriate loading state based on index
    if (index == 0) {
      setState(() => _isAddingFirst = true);
    } else if (index == 1) {
      setState(() => _isAddingSecond = true);
    } else {
      setState(() => _isAddingThird = true);
    }

    setState(() {
      _statusMessage = 'Adding alert #${index + 1} to Firebase...';
    });

    try {
      final mockAlerts = MockDataService.getAlerts();
      
      // Validate index
      if (mockAlerts.length <= index) {
        throw Exception('Alert #${index + 1} not available in mock data');
      }

      // Add single alert to Firebase
      final alert = mockAlerts[index];
      final alertId = await DataService.addAlert(alert);
      
      // Update status with alert details
      setState(() {
        _statusMessage = '✅ Successfully added alert #${index + 1}!\n'
            'Type: ${alert.type}\n'
            'Location: ${alert.location}\n'
            'ID: $alertId';
      });

      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Alert #${index + 1} added: ${alert.type}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle add errors
      setState(() {
        _statusMessage = '❌ Error adding alert #${index + 1}: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset appropriate loading state
      if (index == 0) {
        setState(() => _isAddingFirst = false);
      } else if (index == 1) {
        setState(() => _isAddingSecond = false);
      } else {
        setState(() => _isAddingThird = false);
      }
    }
  }

  /// Tests Firebase connection and displays current database statistics
  /// Shows a dialog with alert counts by severity and resolution status
  Future<void> _testConnection() async {
    setState(() {
      _statusMessage = 'Testing Firebase connection...';
    });

    try {
      // Fetch statistics from Firebase
      final stats = await DataService.getAlertStatistics();
      
      setState(() {
        _statusMessage = '✅ Connected! Found ${stats['total']} alerts in Firebase.';
      });

      // Show detailed statistics dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a2e),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: const Color(0xFF4ECDC4),
                ),
                const SizedBox(width: 12),
                Text(
                  'Firebase Status',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
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
                    '✅ Connected to Firebase\n',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF88),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Display statistics rows
                  _buildStatRow('Total Alerts', '${stats['total']}'),
                  _buildStatRow('High', '${stats['high']}', const Color(0xFFFF6B6B)),
                  _buildStatRow('Medium', '${stats['medium']}', const Color(0xFFFF8E53)),
                  _buildStatRow('Low', '${stats['low']}', const Color(0xFF00FF88)),
                  const Divider(color: Colors.white24),
                  _buildStatRow('Resolved', '${stats['resolved']}', const Color(0xFF00FF88)),
                  _buildStatRow('Unresolved', '${stats['unresolved']}', const Color(0xFFFF6B6B)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4ECDC4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle connection errors
      setState(() {
        _statusMessage = '❌ Connection failed: $e';
      });
    }
  }

  /// Builds a statistics row for the connection test dialog
  /// [label] - The statistic label (e.g., "Total Alerts")
  /// [value] - The statistic value
  /// [color] - Optional color for the value text
  Widget _buildStatRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              // Header with dev mode indicator
              _buildHeader(),
              
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Cloud upload icon with gradient glow
                      _buildHeaderIcon(),
                      const SizedBox(height: 24),
                      
                      // Screen title with gradient shader
                      _buildTitle(),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Upload mock data & test notifications',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Status message display
                      if (_statusMessage.isNotEmpty)
                        _buildStatusMessage(),
                      
                      // Test individual alerts section
                      _buildSectionTitle('Test Individual Alerts', Icons.bug_report),
                      const SizedBox(height: 12),
                      
                      _buildTestAlertButton(
                        'Add Alert #1 (First Mock Alert)',
                        'Test notification with first alert',
                        0,
                        _isAddingFirst,
                        const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTestAlertButton(
                        'Add Alert #2 (Second Mock Alert)',
                        'Test notification with second alert',
                        1,
                        _isAddingSecond,
                        const Color(0xFFFF8E53),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildTestAlertButton(
                        'Add Alert #3 (Third Mock Alert)',
                        'Test notification with third alert',
                        2,
                        _isAddingThird,
                        const Color(0xFFFFD93D),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Bulk operations section
                      _buildSectionTitle('Bulk Operations', Icons.cloud_upload),
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        'Upload All Mock Data',
                        'Upload all sample alerts at once',
                        Icons.upload,
                        _isUploading,
                        _uploadMockData,
                        const Color(0xFF4ECDC4),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        'Test Connection',
                        'Check Firebase connection status',
                        Icons.wifi_tethering,
                        false,
                        _testConnection,
                        const Color(0xFF6C5CE7),
                        isOutlined: true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Admin settings navigation button
                      _buildActionButton(
                        'Admin Settings (Testing)',
                        'Access admin configuration panel',
                        Icons.settings,
                        false,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminSettingsScreen(),
                            ),
                          );
                        },
                        const Color(0xFFFF6B6B),
                        isOutlined: true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Testing instructions
                      _buildInstructions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header with developer mode badge
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Developer mode icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4ECDC4).withOpacity(0.2),
                  const Color(0xFF6C5CE7).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.developer_mode,
              color: Color(0xFF4ECDC4),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Header text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF4ECDC4),
                    Color(0xFF6C5CE7),
                  ],
                ).createShader(bounds),
                child: Text(
                  'TESTING',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                'Development Tools',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white60,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // DEV badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  Icons.warning_amber,
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
        ],
      ),
    );
  }

  /// Builds the header icon with radial gradient glow effect
  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF4ECDC4).withOpacity(0.3),
            const Color(0xFF4ECDC4).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: const Icon(
        Icons.cloud_upload,
        size: 80,
        color: Color(0xFF4ECDC4),
      ),
    );
  }

  /// Builds the screen title with gradient shader effect
  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF4ECDC4),
          Color(0xFF6C5CE7),
        ],
      ).createShader(bounds),
      child: Text(
        'FIREBASE SETUP',
        style: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  /// Builds the status message container
  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            const Color(0xFF1a1a2e).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
        ),
      ),
      child: Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  /// Builds a section title with icon
  /// [title] - The section title text
  /// [icon] - The icon to display
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4ECDC4).withOpacity(0.2),
                const Color(0xFF6C5CE7).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF4ECDC4).withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4ECDC4),
            size: 18,
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
    );
  }

  /// Builds a test alert button for adding individual alerts
  /// [title] - Button title
  /// [subtitle] - Button subtitle/description
  /// [index] - Alert index in mock data
  /// [isLoading] - Loading state flag
  /// [color] - Button accent color
  Widget _buildTestAlertButton(
    String title,
    String subtitle,
    int index,
    bool isLoading,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _addAlertByIndex(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon or loading indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(
                          Icons.add_alert,
                          color: color,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a general action button
  /// [title] - Button title
  /// [subtitle] - Button subtitle/description
  /// [icon] - Button icon
  /// [isLoading] - Loading state flag
  /// [onPressed] - Callback function
  /// [color] - Button accent color
  /// [isOutlined] - Whether to use outlined style instead of filled
  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    bool isLoading,
    VoidCallback onPressed,
    Color color, {
    bool isOutlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isOutlined
            ? null
            : LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
        borderRadius: BorderRadius.circular(16),
        border: isOutlined
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon or loading indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOutlined
                        ? color.withOpacity(0.1)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isOutlined ? color : Colors.white,
                          ),
                        )
                      : Icon(
                          icon,
                          color: isOutlined ? color : Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOutlined ? color : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isOutlined
                              ? Colors.white60
                              : Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isOutlined
                      ? color.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the instructions panel with numbered steps
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            const Color(0xFF1a1a2e).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions header
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF4ECDC4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Testing Instructions',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Instruction steps
          _buildInstructionStep('1', 'Test Firebase connection first'),
          _buildInstructionStep('2', 'Add individual alerts to test notifications'),
          _buildInstructionStep('3', 'Upload all mock data for full testing'),
          _buildInstructionStep('4', 'Check notifications on your device 🔔'),
          _buildInstructionStep('5', 'Visit Admin Settings to test UI'),
          _buildInstructionStep('6', 'Return to app and refresh'),
        ],
      ),
    );
  }

  /// Builds a single instruction step with numbered badge
  /// [number] - Step number
  /// [text] - Instruction text
  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4ECDC4),
                  const Color(0xFF6C5CE7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Instruction text
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
