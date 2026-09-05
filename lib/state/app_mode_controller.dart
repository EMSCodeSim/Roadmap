import 'package:flutter/foundation.dart';

import 'package:firepath/services/department_link_store.dart';
import 'package:firepath/services/local_store.dart';

enum AppExperienceMode { personal, department }

/// Owns the user's current app workspace without mixing personal and
/// department records. The department workspace can be selected before a
/// connection exists so the app can present its native sign-in/join flow.
class AppModeController extends ChangeNotifier {
  AppModeController({
    LocalStore? localStore,
    DepartmentLinkStore? departmentLinkStore,
  })  : _localStore = localStore ?? LocalStore(),
        _departmentLinkStore = departmentLinkStore ?? DepartmentLinkStore();

  static const String _modeKey = 'fireops.experienceMode.v1';

  final LocalStore _localStore;
  final DepartmentLinkStore _departmentLinkStore;

  AppExperienceMode _mode = AppExperienceMode.personal;
  DepartmentLink? _departmentLink;
  bool _bootstrapped = false;
  bool _disposed = false;

  AppExperienceMode get mode => _mode;
  bool get isDepartment => _mode == AppExperienceMode.department;
  bool get bootstrapped => _bootstrapped;
  DepartmentLink? get departmentLink => _departmentLink;
  String get role => _departmentLink?.role ?? 'MEMBER';
  bool get canReview => const {
        'EVALUATOR',
        'TRAINING_OFFICER',
        'DEPARTMENT_ADMINISTRATOR',
      }.contains(role);

  Future<void> bootstrap() async {
    final saved = await _localStore.loadJsonMap(_modeKey);
    _departmentLink = await _departmentLinkStore.load();
    _mode = saved?['mode'] == 'department'
        ? AppExperienceMode.department
        : AppExperienceMode.personal;
    _bootstrapped = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> selectPersonal() => _select(AppExperienceMode.personal);

  Future<void> selectDepartment() => _select(AppExperienceMode.department);

  Future<void> _select(AppExperienceMode value) async {
    if (_mode == value) return;
    _mode = value;
    if (!_disposed) notifyListeners();
    await _localStore.saveJson(
      _modeKey,
      <String, dynamic>{
        'mode': value == AppExperienceMode.department
            ? 'department'
            : 'personal',
      },
    );
  }

  Future<void> setDepartmentLink(DepartmentLink? link) async {
    _departmentLink = link;
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshDepartmentLink() async {
    _departmentLink = await _departmentLinkStore.load();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
