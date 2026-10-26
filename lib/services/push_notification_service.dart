import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/services/notification_preferences_store.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

/// Delivers opt-in device notifications from the canonical department inbox.
/// The first sync establishes a baseline so enabling alerts never floods the
/// user with every historical assignment.
class PushNotificationService {
  static const _snapshotReadyKey = 'fireops.notifications.departmentSnapshotReady';
  static const _seenAssignmentsKey = 'fireops.notifications.seenAssignments';
  static const _seenActionsKey = 'fireops.notifications.seenActions';
  static const _channelId = 'responder_roadmap_department';
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _configured = false;

  static Future<void> configure({
    required ResponderRoadmapApi api,
    required VoidCallback onMessage,
  }) async {
    if (_configured || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _configured = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!_configured) {
      await configure(api: ResponderRoadmapApi(), onMessage: () {});
    }
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  static Future<void> processDepartmentUpdates({
    required DepartmentInbox inbox,
    required List<DepartmentTaskBookAssignment> assignments,
  }) async {
    if (kIsWeb) return;
    if (!_configured) {
      await configure(api: ResponderRoadmapApi(), onMessage: () {});
    }
    final preferences = await NotificationPreferencesStore().load();
    final store = await SharedPreferences.getInstance();
    final assignmentIds = assignments.map((item) => item.id).toSet();
    final actionIds = inbox.needsAction.map((item) => item.id).toSet();
    final baselineReady = store.getBool(_snapshotReadyKey) ?? false;
    final seenAssignments =
        (store.getStringList(_seenAssignmentsKey) ?? const <String>[]).toSet();
    final seenActions =
        (store.getStringList(_seenActionsKey) ?? const <String>[]).toSet();

    if (baselineReady) {
      for (final assignment in assignments.where(
        (item) => !seenAssignments.contains(item.id),
      )) {
        final enabled = assignment.isSingleTask
            ? preferences.assignmentAlerts
            : preferences.taskBookAlerts;
        if (!enabled) continue;
        await _show(
          id: assignment.id.hashCode,
          title: assignment.isSingleTask ? 'New Assignment' : 'New Task Book',
          body: assignment.taskBookTitle,
        );
      }
      if (preferences.needsAttentionAlerts) {
        for (final item in inbox.needsAction.where(
          (action) => !seenActions.contains(action.id),
        )) {
          await _show(
            id: item.id.hashCode,
            title: 'Needs Attention',
            body: item.title,
          );
        }
      }
    }

    await store.setBool(_snapshotReadyKey, true);
    await store.setStringList(_seenAssignmentsKey, assignmentIds.toList());
    await store.setStringList(_seenActionsKey, actionIds.toList());
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) => _plugin.show(
        id & 0x7fffffff,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Department work',
            channelDescription:
                'Task Books, Assignments, and items needing attention',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
}
