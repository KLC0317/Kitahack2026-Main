import 'dart:async';
import '../models/alert_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Service for monitoring and detecting new alerts in real-time.
/// Maintains a list of seen alerts to prevent duplicate notifications.
class AlertMonitorService {
  /// Subscription to the Firebase alerts stream
  static StreamSubscription<List<AlertModel>>? _alertSubscription;
  
  /// List of alert IDs that have already been processed
  static List<String> _seenAlertIds = [];
  
  /// Flag indicating whether the service is currently monitoring alerts
  static bool _isMonitoring = false;
  
  /// Flag to prevent notifications for existing alerts on app startup
  static bool _isInitialLoad = true;

  /// Loads existing alerts without triggering notifications
  static Future<void> initialize() async {
    try {
      final currentAlerts = await FirebaseService.getAlerts();
      
      // Mark all existing alerts as "seen"
      for (var alert in currentAlerts) {
        _seenAlertIds.add(alert.id);
      }
      
      _isInitialLoad = false;
      
    } catch (e) {
      rethrow;
    }
  }

  /// Starts monitoring for new alerts and triggers notifications
  static Future<void> startMonitoring() async {
    if (_isMonitoring) {
      return;
    }

    // Initialize first if not done
    if (_isInitialLoad) {
      await initialize();
    }

    _alertSubscription = FirebaseService.getAlertsStream().listen(
      (alerts) {
        // Check for new alerts
        for (var alert in alerts) {
          // Skip resolved alerts
          if (alert.resolved) continue;

          // Check if this is a new alert we haven't seen
          if (!_seenAlertIds.contains(alert.id)) {
            _seenAlertIds.add(alert.id);
            NotificationService.showAlertNotification(alert);
          }
        }
      },
      onError: (error) {
        // Error handling for stream subscription
      },
    );

    _isMonitoring = true;
  }

  /// Stops monitoring and cancels the stream subscription
  static void stopMonitoring() {
    _alertSubscription?.cancel();
    _alertSubscription = null;
    _isMonitoring = false;
  }

  /// Resets seen alerts list (useful for testing)
  static void resetSeenAlerts() {
    _seenAlertIds.clear();
    _isInitialLoad = true;
  }

  /// Returns whether monitoring is currently active
  static bool get isMonitoring => _isMonitoring;
  
  /// Returns the count of tracked alerts
  static int get trackedAlertsCount => _seenAlertIds.length;
}
