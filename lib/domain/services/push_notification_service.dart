import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub push notification service for debug builds.
/// Firebase Cloud Messaging is disabled in test environment.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;
  bool _notificationsEnabled = false;
  final _tapController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationTap => _tapController.stream;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kDebugMode) {
      debugPrint('[PushNotificationService] Stub initialized (FCM disabled)');
    }
    _initialized = true;
  }

  Future<String?> getToken() async {
    return null;
  }

  Future<bool> requestPermission() async {
    return false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
  }

  Future<void> unregisterToken() async {}
  Future<void> subscribeToTopic(String topic) async {}
  Future<void> unsubscribeFromTopic(String topic) async {}
  Future<void> deleteToken() async {}
}
