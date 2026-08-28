import 'package:flutter/foundation.dart';

import 'package:firepath/services/local_store.dart';

class DepartmentLink {
  final String code;
  final String departmentName;
  final DateTime linkedAt;

  const DepartmentLink({
    required this.code,
    required this.departmentName,
    required this.linkedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'departmentName': departmentName,
        'linkedAt': linkedAt.toIso8601String(),
      };

  static DepartmentLink? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final code = (json['code'] as String?)?.trim();
    final name = (json['departmentName'] as String?)?.trim();
    final linkedAtRaw = json['linkedAt'] as String?;
    if (code == null || code.isEmpty || name == null || name.isEmpty) return null;
    final linkedAt = DateTime.tryParse(linkedAtRaw ?? '') ?? DateTime.now();
    return DepartmentLink(code: code, departmentName: name, linkedAt: linkedAt);
  }
}

class DepartmentLinkStore {
  DepartmentLinkStore({LocalStore? store}) : _store = store ?? LocalStore();

  static const String _kDepartmentLink = 'fireops.department.link.v1';

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
