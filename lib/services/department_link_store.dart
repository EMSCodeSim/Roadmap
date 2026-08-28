import 'package:flutter/foundation.dart';

import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

class DepartmentLink {
  final String departmentId;
  final String departmentName;
  final String userId;
  final String userName;
  final String email;
  final String role;
  final String? rank;
  final DateTime linkedAt;

  const DepartmentLink({
    required this.departmentId,
    required this.departmentName,
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
    required this.rank,
    required this.linkedAt,
  });

  factory DepartmentLink.fromSession(ResponderRoadmapSession session) {
    if (!session.hasDepartment) {
      throw StateError('Cannot create a department link without an active department membership.');
    }
    return DepartmentLink(
      departmentId: session.departmentId!,
      departmentName: session.departmentName ?? 'Department',
      userId: session.userId,
      userName: session.name,
      email: session.email,
      role: session.role ?? 'MEMBER',
      rank: session.rank,
      linkedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'departmentId': departmentId,
        'departmentName': departmentName,
        'userId': userId,
        'userName': userName,
        'email': email,
        'role': role,
        'rank': rank,
        'linkedAt': linkedAt.toIso8601String(),
      };

  static DepartmentLink? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final departmentId = (json['departmentId'] as String?)?.trim() ?? '';
    final departmentName = (json['departmentName'] as String?)?.trim() ?? '';
    final userId = (json['userId'] as String?)?.trim() ?? '';
    final userName = (json['userName'] as String?)?.trim() ?? '';
    final email = (json['email'] as String?)?.trim() ?? '';
    final role = (json['role'] as String?)?.trim() ?? '';
    if (departmentId.isEmpty || departmentName.isEmpty || userId.isEmpty) {
      // Older builds stored only the DEMO-01 placeholder. Treat that as
      // disconnected so the next visit upgrades to the real dashboard link.
      return null;
    }
    final linkedAt = DateTime.tryParse((json['linkedAt'] as String?) ?? '') ??
        DateTime.now();
    return DepartmentLink(
      departmentId: departmentId,
      departmentName: departmentName,
      userId: userId,
      userName: userName.isEmpty ? email : userName,
      email: email,
      role: role.isEmpty ? 'MEMBER' : role,
      rank: json['rank'] as String?,
      linkedAt: linkedAt,
    );
  }
}

class DepartmentLinkStore {
  DepartmentLinkStore({LocalStore? store}) : _store = store ?? LocalStore();

  static const String _kDepartmentLink = 'fireops.department.link.v2';

  final LocalStore _store;

  Future<DepartmentLink?> load() async {
    try {
      final json = await _store.loadJsonMap(_kDepartmentLink);
      return DepartmentLink.fromJson(json);
    } catch (e) {
      debugPrint('DepartmentLinkStore.load failed: $e');
      return null;
    }
  }

  Future<void> save(DepartmentLink link) async {
    try {
      await _store.saveJson(_kDepartmentLink, link.toJson());
    } catch (e) {
      debugPrint('DepartmentLinkStore.save failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _store.removeKey(_kDepartmentLink);
    } catch (e) {
      debugPrint('DepartmentLinkStore.clear failed: $e');
    }
  }
}
