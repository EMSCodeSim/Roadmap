import 'package:firepath/services/fireopssim_links.dart';

class EcosystemRecommendation {
  final String product;
  final String title;
  final String reason;
  final String actionLabel;
  final String url;

  const EcosystemRecommendation({
    required this.product,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.url,
  });
}

class EcosystemRecommendations {
  /// Builds the focused Roadmap → FireOpsSim handoff used by Daily Focus.
  ///
  /// Career Road owns the user's goal/task-book context. FireOpsSim receives
  /// the current training level/topic plus stable Roadmap task identifiers so
  /// it can open the matching drill library and preserve enough context for a
  /// later "Record this drill" return flow. No completion state is transferred.
  static EcosystemRecommendation? forDailyFocus({
    required String topic,
    String? qualification,
    String? goal,
    String? taskId,
    String? requirementId,
    String? certId,
  }) {
    final context = [
      certId,
      qualification,
      topic,
      goal,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    // Prefer explicit certification ids when present (except EMS certs, which
    // should fall through to EMSCodeSim via forTopic). Otherwise resolve from
    // human-readable qualification/topic text.
    final String? level;
    if (_isEmsCert(certId) || _isEmsCert(requirementId)) {
      level = null;
    } else if (certId != null && certId.trim().isNotEmpty) {
      level = FireOpsSimLinks.focusLevelFor(certId);
    } else if (requirementId != null &&
        requirementId.trim().isNotEmpty &&
        _looksLikeFireCertId(requirementId)) {
      level = FireOpsSimLinks.focusLevelFor(requirementId);
    } else {
      level = _fireOpsFocusLevel(context);
    }
    if (level == null) return null;

    final url = FireOpsSimLinks.focusDrills(
      level: level,
      topic: topic,
      taskId: taskId,
      requirementId: requirementId,
      qualification: qualification,
      cert: certId,
      goal: goal,
    ).toString();
    final label = _fireOpsFocusLabel(level);

    return EcosystemRecommendation(
      product: 'FireOpsSim',
      title: '$label Focus Drills',
      reason:
          'Practice this exact Career Road focus in the FireOpsSim $label drill library. Choose the recommended drill or spin the level-specific skill wheel, then return to Career Road to record the work.',
      actionLabel: 'Practice in FireOpsSim',
      url: url,
    );
  }

  static EcosystemRecommendation? forTopic(String? rawTopic) {
    final topic = (rawTopic ?? '').trim().toLowerCase();
    if (topic.isEmpty) return null;

    // Generic callers still get a certification-aware FireOpsSim handoff when
    // the supplied topic itself contains a supported fire-service level.
    final focusRecommendation = forDailyFocus(topic: rawTopic ?? '');
    if (focusRecommendation != null) return focusRecommendation;

    if (_containsAny(topic, const [
      'friction loss',
      'hydraulic',
      'pump discharge',
      'pdp',
      'nozzle pressure',
      'nozzle reaction',
      'hydrant flow',
      'flow calculation',
      'relay',
    ])) {
      return const EcosystemRecommendation(
        product: 'FireOps Calc',
        title: 'Use FireOps Calc for the numbers',
        reason:
            'Your current work involves fireground hydraulics. FireOps Calc can help you practice and check the calculations without leaving the learning workflow.',
        actionLabel: 'Open FireOps Calc',
        url: 'https://fireopscalc.com',
      );
    }

    if (_containsAny(topic, const [
      'driver operator',
      'driver/operator',
      'pumper',
      'pump operator',
      'pump operations',
      'drafting',
      'master stream',
      'apparatus operator',
    ])) {
      return const EcosystemRecommendation(
        product: 'FirePumpSim',
        title: 'Practice the decision in FirePumpSim',
        reason:
            'This is easier to retain when you make the pump-panel decisions yourself. FirePumpSim is the specialized practice tool for this part of your Career Road.',
        actionLabel: 'Practice in FirePumpSim',
        url: 'https://firepumpsim.com',
      );
    }

    if (_containsAny(topic, const [
      'emt',
      'paramedic',
      'aemt',
      'patient assessment',
      'airway',
      'medical assessment',
      'trauma assessment',
      'ems',
    ])) {
      return const EcosystemRecommendation(
        product: 'EMSCodeSim',
        title: 'Practice the patient side in EMSCodeSim',
        reason:
            'Your current development area is EMS-focused. EMSCodeSim provides patient-assessment and decision-making practice that complements the Career Road task.',
        actionLabel: 'Open EMSCodeSim',
        url: 'https://emscodesim.com',
      );
    }

    if (_containsAny(topic, const [
      'fire officer',
      'officer',
      'instructor',
      'hazmat',
      'firefighter',
      'leadership',
      'promotion',
      'cpat',
    ])) {
      return const EcosystemRecommendation(
        product: 'FireOpsSim',
        title: 'Continue learning on FireOpsSim',
        reason:
            'FireOpsSim has free firefighter career, training, leadership, and study resources that fit this part of your development plan.',
        actionLabel: 'Open FireOpsSim',
        url: 'https://fireopssim.com',
      );
    }

    return null;
  }

  static bool _isEmsCert(String? certId) {
    const ems = {'emt', 'aemt', 'paramedic', 'bls', 'acls', 'pals'};
    return ems.contains((certId ?? '').trim().toLowerCase());
  }

  static bool _looksLikeFireCertId(String raw) {
    final n = raw.trim().toLowerCase();
    return n.startsWith('firefighter_') ||
        n.startsWith('fire_officer_') ||
        n.startsWith('fire_instructor_') ||
        n.startsWith('driver_operator') ||
        n.startsWith('hazmat_');
  }

  static String? _fireOpsFocusLevel(String rawTopic) {
    final topic = rawTopic.trim().toLowerCase();
    if (topic.isEmpty) return null;

    // Match the most specific certification names before broad role terms.
    if (_containsAny(topic, const [
      'firefighter ii',
      'firefighter 2',
      'fire fighter 2',
      'ff2',
      'ff ii',
      'firefighter i/ii',
      'firefighter 1 2',
    ])) {
      return 'firefighter_2';
    }
    if (_containsAny(topic, const [
      'firefighter i',
      'firefighter 1',
      'fire fighter 1',
      'ff1',
      'ff i',
    ])) {
      return 'firefighter_1';
    }
    if (_containsAny(topic, const [
      'hazmat',
      'hazardous materials operations',
      'hm ops',
    ])) {
      return 'hazmat_ops';
    }
    if (_containsAny(topic, const [
      'driver operator',
      'driver/operator',
      'driver / operator',
      'pumper',
      'pump operator',
      'pump operations',
      'apparatus operator',
      'engineer',
    ])) {
      return 'driver_operator';
    }
    if (_containsAny(topic, const [
      'fire officer 1',
      'fire officer i',
      'company officer',
      'acting officer',
      'lieutenant',
      'fo1',
    ])) {
      return 'officer_1';
    }
    if (_containsAny(topic, const [
      'fire instructor 1',
      'fire instructor i',
      'instructor 1',
      'instructor i',
      'training officer',
      'fi1',
    ])) {
      return 'instructor_1';
    }
    if (_containsAny(topic, const [
      'probation',
      'probationary',
      'rookie',
      'recruit',
      'academy',
    ])) {
      return 'probationary';
    }
    if (_containsAny(topic, const [
      'firefighter',
      'fireground',
      'structural fire',
    ])) {
      return 'firefighter_2';
    }
    return null;
  }

  static String _fireOpsFocusLabel(String level) => switch (level) {
        'probationary' => 'Academy / Probation',
        'firefighter_1' => 'Firefighter I',
        'firefighter_2' => 'Firefighter II',
        'hazmat_ops' => 'HazMat Operations',
        'driver_operator' => 'Driver / Operator',
        'officer_1' => 'Company Officer I',
        'instructor_1' => 'Fire Instructor I',
        _ => 'Working Firefighter',
      };

  static bool _containsAny(String topic, List<String> terms) =>
      terms.any(topic.contains);
}
