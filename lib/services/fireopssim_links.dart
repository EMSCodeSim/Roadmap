/// Stable FireOpsSim handoff URLs for FireOps Career Road.
/// Keep in sync with FireOpsSim `ROADMAP_SUPPORT_CONTRACT.md` + `js/roadmap-bridge.js`.
class FireOpsSimLinks {
  static const host = 'fireopssim.com';

  /// Map Roadmap certification / requirement ids to focus-drill levels.
  static String focusLevelFor(String? raw) {
    final n = _norm(raw);
    if (n.isEmpty) return 'firefighter_1';
    if (n.contains('probation')) return 'probationary';
    if (n.contains('hazmat') || n.contains('haz_ops')) return 'hazmat_ops';
    if (n.contains('driver') || n.contains('pumper') || n.contains('aerial')) {
      return 'driver_operator';
    }
    if (n.contains('instructor')) return 'instructor_1';
    if (n.contains('officer') || n.contains('lieutenant') || n.contains('captain')) {
      return 'officer_1';
    }
    if (n.contains('firefighter_2') ||
        n.contains('firefighter_ii') ||
        n == 'ff2') {
      return 'firefighter_2';
    }
    if (n.contains('firefighter_1') ||
        n.contains('firefighter_i') ||
        n == 'ff1') {
      return 'firefighter_1';
    }
    return 'firefighter_1';
  }

  static String? pathwayIdFor(String? certId) {
    switch (_norm(certId)) {
      case 'firefighter_1':
        return 'national.firefighter_i';
      case 'firefighter_2':
        return 'national.firefighter_ii';
      case 'driver_operator_pumper':
      case 'driver_operator_aerial':
        return 'national.driver_operator_pumper';
      case 'fire_officer_1':
      case 'fire_officer_2':
        return 'national.fire_officer_i';
      case 'fire_instructor_1':
      case 'fire_instructor_2':
        return 'national.fire_instructor_i';
      default:
        return null;
    }
  }

  static Uri taskbookResources({
    String? cert,
    String? task,
    String? state,
    String? goal,
    String source = 'roadmap',
  }) {
    return Uri.https(host, '/taskbook-resources.html', {
      if (source.isNotEmpty) 'source': source,
      if (cert != null && cert.isNotEmpty) 'cert': cert,
      if (task != null && task.isNotEmpty) 'task': task,
      if (state != null && state.isNotEmpty) 'state': state.toUpperCase(),
      if (goal != null && goal.isNotEmpty) 'goal': goal,
    });
  }

  static Uri roadmapSupport({
    String? task,
    String? cert,
    String? goal,
    String? requirement,
    String? state,
  }) {
    return Uri.https(host, '/roadmap-support.html', {
      if (task != null && task.isNotEmpty) 'task': task,
      if (cert != null && cert.isNotEmpty) 'cert': cert,
      if (goal != null && goal.isNotEmpty) 'goal': goal,
      if (requirement != null && requirement.isNotEmpty) 'requirement': requirement,
      if (state != null && state.isNotEmpty) 'state': state.toUpperCase(),
    });
  }

  static Uri focusDrills({
    String? level,
    String? topic,
    String? task,
    String? taskId,
    String? requirementId,
    String? qualification,
    String? cert,
    String? goal,
    String source = 'roadmap',
  }) {
    final resolved = level ??
        focusLevelFor(cert ?? requirementId ?? taskId ?? task ?? topic);
    final cleanTaskId = (taskId ?? task)?.trim() ?? '';
    return Uri.https(host, '/focus-drills.html', {
      if (source.isNotEmpty) 'source': source,
      if (resolved.isNotEmpty) 'level': resolved,
      if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
      if (qualification != null && qualification.trim().isNotEmpty)
        'qualification': qualification.trim(),
      if (goal != null && goal.isNotEmpty) 'goal': goal,
      if (cleanTaskId.isNotEmpty) 'task_id': cleanTaskId,
      if (requirementId != null && requirementId.trim().isNotEmpty)
        'requirement_id': requirementId.trim(),
      if (cert != null && cert.isNotEmpty) 'cert': cert,
    });
  }

  static Uri pathwayRoadmap({
    String? cert,
    String? pathwayId,
    String? state,
    bool autogen = true,
  }) {
    final pid = pathwayId ?? pathwayIdFor(cert);
    return Uri.https(host, '/pathway-roadmap.html', {
      if (pid != null && pid.isNotEmpty) 'pathway': pid,
      if (pid == null && cert != null && cert.isNotEmpty) 'cert': cert,
      if (state != null && state.isNotEmpty) 'state': state.toUpperCase(),
      if (autogen) 'autogen': '1',
    });
  }

  static Uri studyGuides({String? cert}) {
    return Uri.https(host, '/study-guides.html', {
      if (cert != null && cert.isNotEmpty) 'cert': cert,
    });
  }

  static Uri schoolFinder({
    String? cert,
    String? state,
    String path = 'fire',
  }) {
    return Uri.https(host, '/school-finder.html', {
      'path': path,
      if (cert != null && cert.isNotEmpty) 'cert': cert,
      if (state != null && state.isNotEmpty) 'state': state.toUpperCase(),
    });
  }

  static String _norm(String? raw) => (raw ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s/-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}
