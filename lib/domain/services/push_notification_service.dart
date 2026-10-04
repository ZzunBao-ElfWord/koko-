import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../../network/api_client.dart';

/// Background message handler (must be top-level or static).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

/// Service for managing push notifications (FCM on Android, APNs on iOS).
class PushNotificationService {
  final ApiClient _apiClient;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _deviceToken;
  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;

  final _notificationTapController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTap => _notificationTapController.stream;

  PushNotificationService(this._apiClient);

  /// Initialize Firebase, local notifications, and request permissions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notification permission denied');
      }

      // Initialize local notifications for foreground display
      await _initLocalNotifications();

      // Listen for FCM token refreshes
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      // Get initial token
      _deviceToken = await _firebaseMessaging.getToken();
      if (_deviceToken != null) {
        await _registerToken(_deviceToken!);
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Push notification initialization failed: $e');
      // Non-fatal: app can still function without push
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = _parsePayload(payload);
            _notificationTapController.add(data);
          } catch (_) {}
        }
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'stoat_messages',
      'Stoat Messages',
      description: 'Notifications for new messages and mentions',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (!_notificationsEnabled) return;

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Stoat',
        body: notification.body ?? '',
        payload: data,
      );
    } else {
      // Data-only message: construct notification from data
      final title = data['title'] as String? ?? 'Stoat';
      final body = data['body'] as String? ?? 'New message';
      _showLocalNotification(
        id: message.hashCode,
        title: title,
        body: body,
        payload: data,
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    _notificationTapController.add(data);
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'stoat_messages',
      'Stoat Messages',
      channelDescription: 'Notifications for new messages and mentions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: _encodePayload(payload),
    );
  }

  Future<void> _onTokenRefresh(String token) async {
    _deviceToken = token;
    if (_notificationsEnabled) {
      await _registerToken(token);
    }
  }

  /// Register device token with backend pushd service.
  Future<void> _registerToken(String token) async {
    try {
      final platform = Platform.isIOS ? 'apns' : 'fcm';
      await _apiClient.registerPushToken(token, platform);
    } catch (e) {
      debugPrint('Failed to register push token: $e');
    }
  }

  /// Unregister device token (e.g., on logout).
  Future<void> unregisterToken() async {
    if (_deviceToken != null) {
      try {
        await _apiClient.unregisterPushToken(_deviceToken!);
      } catch (e) {
        debugPrint('Failed to unregister push token: $e');
      }
    }
    _deviceToken = null;
  }

  /// Enable or disable notifications.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    if (enabled && _deviceToken != null) {
      await _registerToken(_deviceToken!);
    } else if (!enabled && _deviceToken != null) {
      await unregisterToken();
    }
  }

  /// Request notification permission (for Android 13+ and iOS).
  Future<bool> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Map<String, dynamic> _parsePayload(String payload) {
    // Simple key-value format: key1=value1&key2=value2
    final result = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        result[Uri.decodeComponent(parts[0])] = Uri.decodeComponent(parts[1]);
      }
    }
    return result;
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  void dispose() {
    _notificationTapController.close();
  }
}
