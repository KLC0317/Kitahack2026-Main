import '../models/alert_model.dart';
import 'mock_data_service.dart';
import 'firebase_service.dart';

/// Unified data service that routes requests to either Firebase or Mock data source
/// Toggle between data sources using the USE_FIREBASE constant
class DataService {
  /// Flag to switch between Firebase and Mock data sources
  static const bool USE_FIREBASE = true;

  // ==================== Stream Methods ====================
  
  /// Returns a stream of all alerts
  static Stream<List<AlertModel>> getAlertsStream() {
    return USE_FIREBASE
        ? FirebaseService.getAlertsStream()
        : MockDataService.getAlertsStream();
  }

  /// Returns a stream of ongoing (unresolved) alerts
  static Stream<List<AlertModel>> getOngoingAlertsStream() {
    return USE_FIREBASE
        ? FirebaseService.getOngoingAlertsStream()
        : MockDataService.getOngoingAlertsStream();
  }

  /// Returns a stream of resolved alerts
  static Stream<List<AlertModel>> getResolvedAlertsStream() {
    return USE_FIREBASE
        ? FirebaseService.getResolvedAlertsStream()
        : MockDataService.getResolvedAlertsStream();
  }

  /// Returns a stream of alerts filtered by floor
  static Stream<List<AlertModel>> getAlertsByFloorStream(String floor) {
    return USE_FIREBASE
        ? FirebaseService.getAlertsByFloorStream(floor)
        : MockDataService.getAlertsByFloorStream(floor);
  }

  // ==================== Future Methods ====================
  
  /// Marks an alert as resolved
  static Future<void> resolveAlert(String alertId) {
    return USE_FIREBASE
        ? FirebaseService.resolveAlert(alertId)
        : MockDataService.resolveAlert(alertId);
  }

  /// Adds a new alert and returns its ID
  static Future<String> addAlert(AlertModel alert) {
    return USE_FIREBASE
        ? FirebaseService.addAlert(alert)
        : MockDataService.addAlert(alert);
  }

  /// Deletes an alert by ID
  static Future<void> deleteAlert(String alertId) {
    return USE_FIREBASE
        ? FirebaseService.deleteAlert(alertId)
        : MockDataService.deleteAlert(alertId);
  }

  /// Updates an existing alert (Mock only)
  static Future<void> updateAlert(String alertId, AlertModel updatedAlert) {
    return USE_FIREBASE
        ? throw UnimplementedError('Firebase updateAlert not implemented')
        : MockDataService.updateAlert(alertId, updatedAlert);
  }

  /// Returns alert statistics (total, ongoing, resolved counts)
  static Future<Map<String, dynamic>> getAlertStatistics() {
    return USE_FIREBASE
        ? FirebaseService.getAlertStatistics()
        : Future.value(MockDataService.getAlertStatistics());
  }

  // ==================== Sync Methods (Mock Only) ====================
  
  /// Returns all alerts synchronously (Mock only, throws error with Firebase)
  static List<AlertModel> getAlerts() {
    if (USE_FIREBASE) {
      throw UnsupportedError(
        'DataService.getAlerts() is synchronous and cannot be used with Firebase. '
        'Use DataService.getAlertsStream() instead.'
      );
    }
    return MockDataService.getAlerts();
  }

  /// Returns alerts filtered by severity (Mock only)
  static List<AlertModel> getAlertsBySeverity(String severity) {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use streams for Firebase');
    }
    return MockDataService.getAlertsBySeverity(severity);
  }

  /// Returns unresolved alerts (Mock only)
  static List<AlertModel> getUnresolvedAlerts() {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use getOngoingAlertsStream() for Firebase');
    }
    return MockDataService.getUnresolvedAlerts();
  }

  /// Returns resolved alerts (Mock only)
  static List<AlertModel> getResolvedAlerts() {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use getResolvedAlertsStream() for Firebase');
    }
    return MockDataService.getResolvedAlerts();
  }

  /// Returns alerts filtered by floor (Mock only)
  static List<AlertModel> getAlertsByFloor(String floor) {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use getAlertsByFloorStream() for Firebase');
    }
    return MockDataService.getAlertsByFloor(floor);
  }

  /// Returns alerts filtered by block (Mock only)
  static List<AlertModel> getAlertsByBlock(String block) {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use streams for Firebase');
    }
    return MockDataService.getAlertsByBlock(block);
  }

  /// Returns alerts filtered by type (Mock only)
  static List<AlertModel> getAlertsByType(String type) {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use streams for Firebase');
    }
    return MockDataService.getAlertsByType(type);
  }

  /// Returns recent alerts (Mock only)
  static List<AlertModel> getRecentAlerts() {
    if (USE_FIREBASE) {
      throw UnsupportedError('Use streams for Firebase');
    }
    return MockDataService.getRecentAlerts();
  }

  /// Returns threat analysis data (Mock only)
  static Map<String, Map<String, dynamic>> getThreatAnalysis() {
    if (USE_FIREBASE) {
      throw UnsupportedError('Not implemented for Firebase yet');
    }
    return MockDataService.getThreatAnalysis();
  }

  /// Returns alerts grouped by date (Mock only)
  static Map<String, List<AlertModel>> getAlertsGroupedByDate() {
    if (USE_FIREBASE) {
      throw UnsupportedError('Not implemented for Firebase yet');
    }
    return MockDataService.getAlertsGroupedByDate();
  }

  /// Returns top alert locations with counts (Mock only)
  static List<Map<String, dynamic>> getTopAlertLocations({int limit = 5}) {
    if (USE_FIREBASE) {
      throw UnsupportedError('Not implemented for Firebase yet');
    }
    return MockDataService.getTopAlertLocations(limit: limit);
  }

  // ==================== Firebase Specific Methods ====================
  
  /// Uploads mock data to Firebase (Firebase only)
  static Future<void> uploadMockData(List<AlertModel> alerts) {
    if (!USE_FIREBASE) {
      throw UnsupportedError('Only available for Firebase');
    }
    return FirebaseService.uploadMockData(alerts);
  }

  /// Clears Firebase stream cache (Firebase only)
  static void clearStreamCache() {
    if (USE_FIREBASE) {
      FirebaseService.clearStreamCache();
    }
  }
}
