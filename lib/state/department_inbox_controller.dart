import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/push_notification_service.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

enum DepartmentSyncState { disconnected, synced, waitingToUpload, failed, syncing }

class DepartmentInboxController extends ChangeNotifier {
  DepartmentInboxController({ResponderRoadmapApi? api, LocalStore? store})
      : _api = api ?? ResponderRoadmapApi(),
        _store = store ?? LocalStore();

  static const _stateKey = 'fireops.departmentSync.v1';
  final ResponderRoadmapApi _api;
  final LocalStore _store;
  Timer? _timer;
  DepartmentInbox? _inbox;
  DepartmentSyncState _syncState = DepartmentSyncState.disconnected;
  DateTime? _lastSyncedAt;
  String? _lastError;
  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  DepartmentInbox? get inbox => _inbox;
  int get unreadCount => _inbox?.unreadCount ?? 0;
  int get actionCount => _inbox?.needsAction.length ?? 0;
  DepartmentSyncState get syncState => _syncState;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  Future<void> bootstrap() async {
    final saved = await _store.loadJsonMap(_stateKey);
    _lastSyncedAt = DateTime.tryParse((saved?['lastSyncedAt'] as String?) ?? '');
    _lastError = saved?['lastError'] as String?;
    if (await _api.hasStoredToken) await refresh(silent: true);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh(silent: true));
    _safeNotify();
  }

  Future<void> refresh({bool silent = false}) async {
    if (_syncState == DepartmentSyncState.syncing) return;
    if (!await _api.hasStoredToken) {
      _syncState = DepartmentSyncState.disconnected;
      _safeNotify();
      return;
    }
    _syncState = DepartmentSyncState.syncing;
    if (!silent) _safeNotify();
    try {
      await _api.retryPendingSubmissions();
      final pending = await _api.pendingSubmissionCount();
      _inbox = await _api.getInbox();
      _lastSyncedAt = _inbox?.serverTime ?? DateTime.now();
      _lastError = null;
      _syncState = pending > 0 ? DepartmentSyncState.waitingToUpload : DepartmentSyncState.synced;
      await PushNotificationService.configure(api: _api, onMessage: () => refresh(silent: true));
    } on ResponderRoadmapApiException catch (error) {
      final pending = await _api.pendingSubmissionCount();
      _lastError = error.message;
      _syncState = pending > 0 ? DepartmentSyncState.waitingToUpload : DepartmentSyncState.failed;
    }
    await _store.saveJson(_stateKey, {
      'lastSyncedAt': _lastSyncedAt?.toIso8601String(),
      'lastError': _lastError,
      'state': _syncState.name,
    });
    _safeNotify();
  }

  Future<void> markRead(String id) async {
    await _api.markInboxRead(id);
    await refresh(silent: true);
  }

  Future<void> markAllRead() async {
    await _api.markAllInboxRead();
    await refresh(silent: true);
  }

  void submissionQueued() {
    _syncState = DepartmentSyncState.waitingToUpload;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
