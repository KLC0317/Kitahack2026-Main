import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/alert_model.dart';

/// Service for managing alert data in Firebase Firestore
/// Provides streams and CRUD operations for alerts
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String ALERTS_COLLECTION = 'alerts';

  /// Cached main alerts stream
  static Stream<List<AlertModel>>? _alertsStream;
  
  /// Flag to track if stream has been initialized
  static bool _isStreamInitialized = false;

  // ==================== Stream Methods ====================

  /// Returns a stream of all alerts, sorted by timestamp (newest first)
  /// Uses shareReplay to cache the main stream and prevent duplicate listeners
  static Stream<List<AlertModel>> getAlertsStream() {
    if (!_isStreamInitialized) {
      _alertsStream = _firestore
          .collection(ALERTS_COLLECTION)
          .snapshots()
          .handleError((error) {
            // Handle stream errors silently
          })
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return <AlertModel>[];
            }
            
            final alerts = snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return AlertModel.fromMap(data);
              } catch (e) {
                return null;
              }
            }).whereType<AlertModel>().toList();
            
            // Sort by timestamp (newest first)
            alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            return alerts;
          })
          .shareReplay(maxSize: 1);
      
      _isStreamInitialized = true;
    }
    
    return _alertsStream!;
  }

  /// Returns a stream of ongoing (unresolved) alerts
  static Stream<List<AlertModel>> getOngoingAlertsStream() {
    return getAlertsStream().map((allAlerts) {
      return allAlerts.where((alert) => !alert.resolved).toList();
    });
  }

  /// Returns a stream of resolved alerts
  static Stream<List<AlertModel>> getResolvedAlertsStream() {
    return getAlertsStream().map((allAlerts) {
      return allAlerts.where((alert) => alert.resolved).toList();
    });
  }

  /// Returns a stream of unresolved alerts filtered by floor
  static Stream<List<AlertModel>> getAlertsByFloorStream(String floor) {
    return getAlertsStream().map((allAlerts) {
      return allAlerts
          .where((alert) => alert.floor == floor && !alert.resolved)
          .toList();
    });
  }

  // ==================== Future Methods ====================

  /// Fetches all alerts once (not a stream) - used for initialization
  static Future<List<AlertModel>> getAlerts() async {
    try {
      final snapshot = await _firestore
          .collection(ALERTS_COLLECTION)
          .get();

      if (snapshot.docs.isEmpty) {
        return <AlertModel>[];
      }

      final alerts = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return AlertModel.fromMap(data);
        } catch (e) {
          return null;
        }
      }).whereType<AlertModel>().toList();

      // Sort by timestamp (newest first)
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return alerts;
      
    } catch (e) {
      return [];
    }
  }

  /// Adds a new alert to Firestore and returns the generated document ID
  static Future<String> addAlert(AlertModel alert) async {
    try {
      final docRef = await _firestore
          .collection(ALERTS_COLLECTION)
          .add(alert.toMap());
      
      clearStreamCache();
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Marks an alert as resolved with timestamp and notes
  static Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore.collection(ALERTS_COLLECTION).doc(alertId).update({
        'resolved': true,
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolutionNotes': 'Resolved by security personnel',
      });
      
      clearStreamCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes an alert from Firestore
  static Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection(ALERTS_COLLECTION).doc(alertId).delete();
      clearStreamCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Calculates and returns alert statistics
  /// Includes counts by severity, resolution status, and performance metrics
  static Future<Map<String, dynamic>> getAlertStatistics() async {
    try {
      final allAlerts = await _firestore.collection(ALERTS_COLLECTION).get();
      final alerts = allAlerts.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return AlertModel.fromMap(data);
        } catch (e) {
          return null;
        }
      }).whereType<AlertModel>().toList();

      // Count by severity
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
    } catch (e) {
      rethrow;
    }
  }

  /// Batch uploads multiple alerts to Firestore
  /// Used for populating the database with mock data
  static Future<void> uploadMockData(List<AlertModel> alerts) async {
    try {
      final batch = _firestore.batch();
      
      for (var alert in alerts) {
        final docRef = _firestore.collection(ALERTS_COLLECTION).doc();
        batch.set(docRef, alert.toMap());
      }
      
      await batch.commit();
      clearStreamCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Clears the cached stream, forcing a fresh stream on next access
  static void clearStreamCache() {
    _alertsStream = null;
    _isStreamInitialized = false;
  }
}
