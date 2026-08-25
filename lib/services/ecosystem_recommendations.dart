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
  /// only the current training level/topic so it can open the matching drill
  /// library and level-specific skill wheel. No completion state is transferred.
  static EcosystemRecommendation? forDailyFocus({
    required String topic,
    String? qualification,
    String? goal,
    String? certId,
    String? taskId,
  }) {
    final context = [
      certId,
      qualification,
      topic,
      goal,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
    final level = _isEmsCert(certId)
        ? null
        : (certId != null && certId.trim().isNotEmpty)
            ? FireOpsSimLinks.focusLevelFor(certId)
            : _fireOpsFocusLevel(context);
    if (level == null) return null;

    final url = FireOpsSimLinks.focusDrills(
      level: level,
      topic: topic,
      task: taskId,
      cert: certId,
      goal: goal,
    ).toString();
    final label = _fireOpsFocusLabel(level);

    return EcosystemRecommendation(
      product: 'FireOpsSim',
      title: '$label Focus Drills',
      reason:
          'Open the FireOpsSim drill library matched to this training level. Pick a focused drill for today or spin the $label skill wheel for a random level-appropriate rep.',
      actionLabel: 'Open Focus Drills',
      url: url,
    );
  }

  static EcosystemRecommendation? forTopic(
    String? rawTopic, {
    String? certId,
    String? taskId,
    String? goal,
    String? qualification,
  }) {
    final topic = (rawTopic ?? '').trim().toLowerCase();
    if (topic.isEmpty && (certId == null || certId.trim().isEmpty)) return null;

    // Daily Focus already passes its current task and qualification through
    // this method. Prefer a certification-aware FireOpsSim handoff whenever
    // that context resolves to a supported fire-service training level.
    final focusRecommendation = forDailyFocus(
      topic: rawTopic ?? '',
      qualification: qualification,
      goal: goal,
      certId: certId,
      taskId: taskId,
    );
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
        ]) ||
        (certId != null && certId.trim().isNotEmpty)) {
      final pathway = FireOpsSimLinks.pathwayIdFor(certId);
      final url = pathway != null
          ? FireOpsSimLinks.pathwayRoadmap(cert: certId).toString()
          : FireOpsSimLinks.taskbookResources(
              cert: certId,
              task: taskId,
              goal: goal,
            ).toString();
      return EcosystemRecommendation(
        product: 'FireOpsSim',
        title: pathway != null
            ? 'Open the full pathway roadmap'
            : 'Continue learning on FireOpsSim',
        reason:
            'FireOpsSim has free firefighter career, training, leadership, and study resources that fit this part of your development plan—with deep links that keep your Roadmap context.',
        actionLabel:
            pathway != null ? 'Open pathway roadmap' : 'Open FireOpsSim',
        url: url,
      );
    }

    return null;
  }

  static bool _isEmsCert(String? certId) {
    const ems = {'emt', 'aemt', 'paramedic', 'bls', 'acls', 'pals'};
    return ems.contains((certId ?? '').trim().toLowerCase());
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
