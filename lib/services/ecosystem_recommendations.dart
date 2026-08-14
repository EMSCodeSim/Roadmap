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
  static EcosystemRecommendation? forTopic(String? rawTopic) {
    final topic = (rawTopic ?? '').trim().toLowerCase();
    if (topic.isEmpty) return null;

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

  static bool _containsAny(String topic, List<String> terms) =>
      terms.any(topic.contains);
}
