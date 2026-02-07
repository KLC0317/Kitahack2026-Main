import '../models/alert_model.dart';

/// Mock data service providing simulated alert data for testing and development
/// Contains pre-defined alerts and methods to manipulate them
class MockDataService {
  /// Internal list of mock alerts
  static final List<AlertModel> _mockAlerts = [
    AlertModel(
      id: '1',
      location: 'Cafeteria',
      type: 'Physical Aggression',
      severity: 'HIGH',
      details:
          'Gemini AI Analysis: Two students detected in physical confrontation. Body language indicates escalating conflict. Immediate intervention recommended. Facial expressions show high emotional distress.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      resolved: false,
      detectedBy: 'Camera #B-CAF-01',
      description: 'Two students detected in physical confrontation near the lunch counter. Body language indicates escalating conflict with aggressive posturing. Immediate intervention recommended. Facial expressions show high emotional distress. Security personnel have been notified.',
      confidenceScore: 0.96,
      tags: ['physical', 'aggression', 'urgent', 'students'],
      assignedTo: 'Security Officer Martinez',
      floor: 'Ground',
      block: 'B',
      responseTime: 45,
      metadata: {
        'cameraId': 'CAM-B-CAF-01',
        'detectionMethod': 'behavior_analysis',
        'alertLevel': 'critical',
        'studentsInvolved': 2,
        'witnessCount': 12,
      },
    ),
    AlertModel(
      id: '2',
      location: 'Class 2B',
      type: 'Verbal Bullying',
      severity: 'MEDIUM',
      details:
          'Gemini AI Analysis: Group of 3 students surrounding 1 individual. Aggressive posturing detected. Victim showing signs of distress and attempting to create distance.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      resolved: false,
      detectedBy: 'Camera #B-2B-03',
      description:
          'Group of 3 students surrounding 1 individual in classroom corner. Aggressive posturing and pointing gestures detected. Victim showing defensive body language, signs of distress, and attempting to create distance. Teacher has been alerted.',
      confidenceScore: 0.87,
      tags: ['verbal', 'bullying', 'group', 'classroom'],
      assignedTo: 'Counselor Dr. Smith',
      floor: 'First',
      block: 'B',
      responseTime: 120,
      metadata: {
        'cameraId': 'CAM-B-2B-03',
        'detectionMethod': 'group_behavior_analysis',
        'alertLevel': 'moderate',
        'studentsInvolved': 4,
        'duration': '3 minutes',
      },
    ),
    AlertModel(
      id: '3',
      location: 'Playground',
      type: 'Social Exclusion',
      severity: 'LOW',
      details:
          'Gemini AI Analysis: Student consistently isolated during break time. Peers forming groups while subject remains alone. Pattern observed over 3 consecutive days.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      resolved: false,
      detectedBy: 'Camera #A-PLAY-02',
      description:
          'Student consistently isolated during break time over multiple days. Peers forming groups while subject remains alone near the fence area. Pattern observed over 3 consecutive days. Counseling session recommended.',
      confidenceScore: 0.73,
      tags: ['social', 'exclusion', 'isolation', 'pattern'],
      assignedTo: 'School Counselor',
      floor: 'Ground',
      block: 'A',
      responseTime: 300,
      metadata: {
        'cameraId': 'CAM-A-PLAY-02',
        'detectionMethod': 'pattern_recognition',
        'alertLevel': 'low',
        'patternDays': 3,
        'isolationDuration': '15+ minutes',
      },
    ),
  ];

  // ==================== Synchronous Methods ====================

  /// Returns a copy of all mock alerts
  static List<AlertModel> getAlerts() {
    return List.from(_mockAlerts);
  }

  /// Returns alerts filtered by severity level
  static List<AlertModel> getAlertsBySeverity(String severity) {
    return _mockAlerts
        .where((alert) => alert.severity.toUpperCase() == severity.toUpperCase())
        .toList();
  }

  /// Returns all unresolved alerts
  static List<AlertModel> getUnresolvedAlerts() {
    return _mockAlerts.where((alert) => !alert.resolved).toList();
  }

  /// Returns all resolved alerts
  static List<AlertModel> getResolvedAlerts() {
    return _mockAlerts.where((alert) => alert.resolved).toList();
  }

  /// Returns alerts filtered by floor
  static List<AlertModel> getAlertsByFloor(String floor) {
    return _mockAlerts.where((alert) => alert.floor == floor).toList();
  }

  /// Returns alerts filtered by block
  static List<AlertModel> getAlertsByBlock(String block) {
    return _mockAlerts.where((alert) => alert.block == block).toList();
  }

  /// Returns alerts filtered by type
  static List<AlertModel> getAlertsByType(String type) {
    return _mockAlerts
        .where((alert) => alert.type.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Returns alerts from the last 24 hours
  static List<AlertModel> getRecentAlerts() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _mockAlerts
        .where((alert) => alert.timestamp.isAfter(yesterday))
        .toList();
  }

  // ==================== Stream Methods ====================

  /// Returns a broadcast stream of all alerts, updated every second
  static Stream<List<AlertModel>> getAlertsStream() {
    return Stream<List<AlertModel>>.periodic(const Duration(seconds: 1), (_) {
      return List<AlertModel>.from(_mockAlerts);
    }).asBroadcastStream();
  }

  /// Returns a broadcast stream of ongoing (unresolved) alerts
  static Stream<List<AlertModel>> getOngoingAlertsStream() {
    return Stream<List<AlertModel>>.periodic(const Duration(seconds: 1), (_) {
      return _mockAlerts.where((alert) => !alert.resolved).toList();
    }).asBroadcastStream();
  }

  /// Returns a broadcast stream of resolved alerts
  static Stream<List<AlertModel>> getResolvedAlertsStream() {
    return Stream<List<AlertModel>>.periodic(const Duration(seconds: 1), (_) {
      return _mockAlerts.where((alert) => alert.resolved).toList();
    }).asBroadcastStream();
  }

  /// Returns a broadcast stream of unresolved alerts filtered by floor
  static Stream<List<AlertModel>> getAlertsByFloorStream(String floor) {
    return Stream<List<AlertModel>>.periodic(const Duration(seconds: 1), (_) {
      return _mockAlerts
          .where((alert) => alert.floor == floor && !alert.resolved)
          .toList();
    }).asBroadcastStream();
  }

  // ==================== Statistics & Analysis ====================

  /// Returns comprehensive alert statistics including counts and averages
  static Map<String, dynamic> getAlertStatistics() {
    final alerts = _mockAlerts;
    final highAlerts = alerts.where((a) => a.severity == 'HIGH').length;
    final mediumAlerts = alerts.where((a) => a.severity == 'MEDIUM').length;
    final lowAlerts = alerts.where((a) => a.severity == 'LOW').length;
    final resolved = alerts.where((a) => a.resolved).length;
    
    // Calculate average response time
    final alertsWithResponseTime = alerts.where((a) => a.responseTime != null).toList();
    final avgResponseTime = alertsWithResponseTime.isEmpty
        ? 0
        : alertsWithResponseTime
            .map((a) => a.responseTime!)
            .reduce((a, b) => a + b) /
            alertsWithResponseTime.length;

    // Calculate average confidence score
    final alertsWithConfidence = alerts.where((a) => a.confidenceScore != null).toList();
    final avgConfidence = alertsWithConfidence.isEmpty
        ? 0.0
        : alertsWithConfidence
            .map((a) => a.confidenceScore!)
            .reduce((a, b) => a + b) /
            alertsWithConfidence.length;

    return {
      'total': alerts.length,
      'high': highAlerts,
      'medium': mediumAlerts,
      'low': lowAlerts,
      'resolved': resolved,
      'unresolved': alerts.length - resolved,
      'avgResponseTime': avgResponseTime.round(),
      'avgConfidence': (avgConfidence * 100).toStringAsFixed(1),
      'accuracy': 98.3,
      'falsePositiveRate': 1.2,
      'systemUptime': 99.9,
    };
  }

  /// Returns threat analysis grouped by alert type with severity breakdown
  static Map<String, Map<String, dynamic>> getThreatAnalysis() {
    final alerts = _mockAlerts;
    Map<String, Map<String, dynamic>> threatTypes = {};
    
    for (var alert in alerts) {
      if (!threatTypes.containsKey(alert.type)) {
        threatTypes[alert.type] = {
          'count': 0,
          'highSeverity': 0,
          'mediumSeverity': 0,
          'lowSeverity': 0,
        };
      }
      
      threatTypes[alert.type]!['count'] = 
          (threatTypes[alert.type]!['count'] as int) + 1;
      
      switch (alert.severity.toUpperCase()) {
        case 'HIGH':
          threatTypes[alert.type]!['highSeverity'] = 
              (threatTypes[alert.type]!['highSeverity'] as int) + 1;
          break;
        case 'MEDIUM':
          threatTypes[alert.type]!['mediumSeverity'] = 
              (threatTypes[alert.type]!['mediumSeverity'] as int) + 1;
          break;
        case 'LOW':
          threatTypes[alert.type]!['lowSeverity'] = 
              (threatTypes[alert.type]!['lowSeverity'] as int) + 1;
          break;
      }
    }
    
    return threatTypes;
  }

  /// Returns alerts grouped by date (YYYY-MM-DD format)
  static Map<String, List<AlertModel>> getAlertsGroupedByDate() {
    final alerts = _mockAlerts;
    Map<String, List<AlertModel>> grouped = {};
    
    for (var alert in alerts) {
      final dateKey = '${alert.timestamp.year}-${alert.timestamp.month.toString().padLeft(2, '0')}-${alert.timestamp.day.toString().padLeft(2, '0')}';
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(alert);
    }
    
    return grouped;
  }

  /// Returns top alert locations sorted by frequency
  static List<Map<String, dynamic>> getTopAlertLocations({int limit = 5}) {
    final alerts = _mockAlerts;
    Map<String, int> locationCounts = {};
    
    for (var alert in alerts) {
      locationCounts[alert.location] = (locationCounts[alert.location] ?? 0) + 1;
    }
    
    var sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedLocations
        .take(limit)
        .map((entry) => {
              'location': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  // ==================== CRUD Operations ====================

  /// Marks an alert as resolved with timestamp and notes
  static Future<void> resolveAlert(String alertId) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockAlerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _mockAlerts[index] = _mockAlerts[index].copyWith(
        resolved: true,
        resolvedAt: DateTime.now(),
        resolutionNotes: 'Resolved by security personnel',
      );
    }
  }

  /// Adds a new alert and returns its ID
  static Future<String> addAlert(AlertModel alert) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAlerts.add(alert);
    return alert.id;
  }

  /// Deletes an alert by ID
  static Future<void> deleteAlert(String alertId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAlerts.removeWhere((alert) => alert.id == alertId);
  }

  /// Updates an existing alert
  static Future<void> updateAlert(String alertId, AlertModel updatedAlert) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockAlerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _mockAlerts[index] = updatedAlert;
    }
  }
}
