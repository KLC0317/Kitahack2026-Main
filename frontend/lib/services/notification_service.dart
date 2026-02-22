import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/alert_model.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Service for managing local and push notifications
/// Handles alert notifications with different priority levels and channels
class NotificationService {
  /// Flutter local notifications plugin instance
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  /// Firebase Cloud Messaging instance
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// Flag to track initialization status
  static bool _isInitialized = false;

  /// Initializes the notification service with permissions and channels
  /// Requests user permissions and sets up notification channels for Android
  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Request notification permissions
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      // Get FCM token for push notifications
      await _firebaseMessaging.getToken();

      _isInitialized = true;
      
    } catch (e) {
      // Initialization failed
    }
  }

  /// Creates Android notification channels for different priority levels
  /// High, Medium, and Low priority channels with appropriate settings
  static Future<void> _createNotificationChannels() async {
    // High priority channel for critical alerts
    const highChannel = AndroidNotificationChannel(
      'high_alerts',
      'High Priority Alerts',
      description: 'Critical security alerts requiring immediate attention',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF6B6B),
    );

    // Medium priority channel
    const mediumChannel = AndroidNotificationChannel(
      'medium_alerts',
      'Medium Priority Alerts',
      description: 'Important security alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Low priority channel
    const lowChannel = AndroidNotificationChannel(
      'low_alerts',
      'Low Priority Alerts',
      description: 'General security notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(highChannel);
    await androidPlugin?.createNotificationChannel(mediumChannel);
    await androidPlugin?.createNotificationChannel(lowChannel);
  }

  /// Shows a notification for a new alert
  /// Notification style and priority are determined by alert severity
  static Future<void> showAlertNotification(AlertModel alert) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Determine channel and priority based on severity
      String channelId;
      Importance importance;
      Priority priority;
      Color ledColor;

      switch (alert.severity.toUpperCase()) {
        case 'HIGH':
          channelId = 'high_alerts';
          importance = Importance.max;
          priority = Priority.high;
          ledColor = const Color(0xFFFF6B6B);
          break;
        case 'MEDIUM':
          channelId = 'medium_alerts';
          importance = Importance.high;
          priority = Priority.defaultPriority;
          ledColor = const Color(0xFFFF8E53);
          break;
        case 'LOW':
        default:
          channelId = 'low_alerts';
          importance = Importance.defaultImportance;
          priority = Priority.low;
          ledColor = const Color(0xFF9CCC65);
          break;
      }

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        '${alert.severity} Priority Alerts',
        channelDescription: 'Security alerts',
        importance: importance,
        priority: priority,
        ticker: 'New ${alert.severity} alert',
        icon: '@mipmap/ic_launcher',
        color: ledColor,
        ledColor: ledColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        playSound: true,
        styleInformation: BigTextStyleInformation(
          alert.details,
          contentTitle: '🚨 ${alert.type}',
          summaryText: '${alert.location} • ${alert.severity}',
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
        ),
        actions: [
          const AndroidNotificationAction(
            'view',
            'View Details',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'resolve',
            'Mark Resolved',
            showsUserInterface: false,
          ),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        subtitle: alert.location,
        threadIdentifier: 'security_alerts',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _localNotifications.show(
        alert.id.hashCode,
        '🚨 ${alert.type}',
        '${alert.location} • ${alert.severity} Priority',
        notificationDetails,
        payload: alert.id,
      );
      
    } catch (e) {
      // Failed to show notification
    }
  }

  /// Handles notification tap events
  /// Processes different actions like view or resolve
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification actions
    if (response.actionId == 'view') {
      // Navigate to details screen
    } else if (response.actionId == 'resolve') {
      // Resolve the alert
    }
  }

  /// Cancels a specific notification by alert ID
  static Future<void> cancelNotification(String alertId) async {
    await _localNotifications.cancel(alertId.hashCode);
  }

  /// Cancels all active notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Shows a test notification to verify the service is working
  static Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Create test channel
    const testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Notifications',
      description: 'Test notification channel',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(testChannel);

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999,
      '🔔 Test Notification',
      'If you see this, notifications are working!',
      notificationDetails,
    );
  }
}
