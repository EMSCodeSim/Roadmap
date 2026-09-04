import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

class PushNotificationService {
  static bool _configured = false;

  static Future<void> configure({
    required ResponderRoadmapApi api,
    required VoidCallback onMessage,
  }) async {
    if (_configured || kIsWeb) return;
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const iosBundleId = String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.fireopssim.careerroadmap',
    );
    if ([apiKey, appId, projectId, senderId].any((value) => value.isEmpty)) return;

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
          iosBundleId: iosBundleId,
        ),
      );
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await api.registerPushDevice(
          token: token,
          platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        );
      }
      messaging.onTokenRefresh.listen((value) async {
        await api.registerPushDevice(
          token: value,
          platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        );
      });
      FirebaseMessaging.onMessage.listen((_) => onMessage());
      _configured = true;
    } catch (error) {
      debugPrint('Push notification setup deferred: $error');
    }
  }
}
