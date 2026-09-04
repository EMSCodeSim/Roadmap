import 'package:flutter/foundation.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

class PushNotificationService {
  static bool _configured = false;

  static Future<void> configure({
    required ResponderRoadmapApi api,
    required VoidCallback onMessage,
  }) async {
    // This project currently runs with no backend connected in Dreamflow.
    // Keep push notifications as a safe no-op until Firebase is wired up via
    // the Firebase panel.
    if (_configured || kIsWeb) return;
    debugPrint('Push notifications not configured (no backend connected).');
    _configured = true;
  }
}
