import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  static Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } else {
      print('Topic subscription skipped on web');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
