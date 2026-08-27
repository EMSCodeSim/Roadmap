import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';

/// Versioned, paraphrased national professional-qualification baselines.
///
/// These are not official NFPA skill sheets and do not reproduce NFPA text.
/// They organize Roadmap checklist objectives around current national
/// professional-qualification / EMS education structures so users can layer
/// state, AHJ, academy, and department requirements on top.
class NationalTaskBookBaseline {
  NationalTaskBookBaseline._();

  static NationalTaskBookStandard? standardFor(Requirement requirement) =>
      standardForCertificationId(requirement.certificationDefinitionId);

  /// Resolves the national baseline directly from a stable catalog cert id.
  /// Kept public so catalog contract tests can guarantee every built-in
  /// certification has a non-empty checklist.
  static NationalTaskBookStandard? standardForCertificationId(String? id) {
    switch (id) {
      case 'firefighter_1':
        return _build('nfpa1010_2024_ff1', 'NFPA 1010', '2024', 'Chapter 6', _ff1);
      case 'firefighter_2':
        return _build('nfpa1010_2024_ff2', 'NFPA 1010', '2024', 'Chapter 7', _ff2);
      case 'hazmat_awareness':
        return _build('nfpa470_2022_awareness', 'NFPA 470', '2022', 'Chapter 5', _hazmatAwareness);
      case 'hazmat_operations':
        return _build('nfpa470_2022_operations', 'NFPA 470', '2022', 'Chapters 5 + 7', _hazmatOperations);
      case 'driver_operator_pumper':
        return _build('nfpa1010_2024_pumper', 'NFPA 1010', '2024', 'Chapters 11 + 12', _pumper);
      case 'emt':
        return _build(
          'national_ems_education_2021_emt',
          'National EMS Education Standards',
          '2021',
          'EMT level',
          _emt,
        );
      case 'aemt':
        return _build(
          'national_ems_education_2021_aemt',
          'National EMS Education Standards',
          '2021',
          'AEMT level',
          _aemt,
        );
      case 'paramedic':
        return _build(
          'national_ems_education_2021_paramedic',
          'National EMS Education Standards',
          '2021',
          'Paramedic level',
          _paramedic,
        );
      case 'fire_instructor_1':
        return _build('nfpa1020_2025_fi1', 'NFPA 1020', '2025', 'Chapter 4', _fi1);
      case 'fire_officer_1':
        return _build('nfpa1020_2025_fo1', 'NFPA 1020', '2025', 'Chapter 9', _fo1);
      case 'fire_officer_2':
        return _build('nfpa1020_2025_fo2', 'NFPA 1020', '2025', 'Chapter 10', _fo2);
      case 'fire_officer_3':
        return _build('nfpa1020_2025_fo3', 'NFPA 1020', '2025', 'Chapter 11', _fo3);
      case 'fire_officer_4':
        return _build('nfpa1020_2025_fo4', 'NFPA 1020', '2025', 'Chapter 12', _fo4);
    }
    return null;
  }

  static List<RequirementPlanStep> effectiveSteps(
    Requirement requirement,
    Iterable<RequirementPlanStep> saved,
  ) {
    final baseline = standardFor(requirement)?.steps ?? const <RequirementPlanStep>[];
    if (baseline.isEmpty) return saved.toList(growable: false);
    final savedById = {for (final item in saved) item.id: item};
    return [
      for (final item in baseline) savedById.remove(item.id) ?? item,
      ...savedById.values,
    ];
  }

  static List<RequirementSubTask> effectiveSubTasks(
    Requirement requirement,
    Iterable<RequirementSubTask> saved,
  ) {
    final baseline = standardFor(requirement)?.subTasks ?? const <RequirementSubTask>[];
    if (baseline.isEmpty) return saved.toList(growable: false);
    final savedById = {for (final item in saved) item.id: item};
    return [
      for (final item in baseline) savedById.remove(item.id) ?? item,
      ...savedById.values,
    ];
  }

  static bool isNationalItem(String id) => id.startsWith('nat_');

  static NationalTaskBookStandard _build(
    String id,
    String standard,
    String edition,
    String chapter,
    List<_Group> groups,
  ) {
    final steps = <RequirementPlanStep>[];
    final subTasks = <RequirementSubTask>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final stepId = 'nat_${id}_g${i + 1}';
      steps.add(RequirementPlanStep(
        id: stepId,
        title: group.title,
        isDone: false,
        notes: '$standard $edition • $chapter',
        url: null,
        estimatedMinutes: null,
      ));
      for (var j = 0; j < group.items.length; j++) {
        final child = RequirementSubTask(
          id: '${stepId}_i${j + 1}',
          title: group.items[j],
          isDone: false,
          notes: null,
        );
        subTasks.add(TaskBookChecklistHierarchy.attachToStep(
          child,
          stepId,
          visibleNotes:
              '$standard $edition • $chapter • paraphrased national competency',
        ));
      }
    }
    return NationalTaskBookStandard(
      id: id,
      standard: standard,
      edition: edition,
      chapter: chapter,
      steps: steps,
      subTasks: subTasks,
    );
  }

  // Keep the order/count of existing groups stable: the generated nat_* IDs
  // are used as persistence keys for user checklist progress.
  static const _ff1 = <_Group>[
    _Group('General readiness and safety', [
      'Use PPE and SCBA safely for assigned tasks.',
      'Work within incident command and maintain crew accountability.',
      'Recognize common hazards and communicate changing conditions.',
    ]),
    _Group('Fireground operations', [
      'Deploy and operate attack hose lines for assigned fire conditions.',
      'Select and place ground ladders for common assignments.',
      'Perform forcible entry using appropriate tools and techniques.',
      'Perform coordinated ventilation and property-conservation tasks.',
    ]),
    _Group('Search, rescue, and survival', [
      'Conduct an assigned search while maintaining orientation and team integrity.',
      'Remove or assist a victim using appropriate rescue methods.',
      'Demonstrate firefighter emergency communications and basic self-rescue actions.',
    ]),
    _Group('Water supply, tools, and equipment', [
      'Establish an assigned water-supply connection.',
      'Operate portable extinguishers and common fireground tools.',
      'Inspect, clean, and return hose, tools, and equipment to service.',
    ]),
  ];

  static const _ff2 = <_Group>[
    _Group('Advanced fireground operations', [
      'Coordinate assigned fireground tasks as part of a team.',
      'Control an ignitable-liquid fire using appropriate agent and tactics.',
      'Protect evidence and preserve observations related to fire cause.',
    ]),
    _Group('Rescue and extrication support', [
      'Perform vehicle-extrication support with stabilization and approved tools.',
      'Assist technical-rescue operations within the Firefighter II role.',
    ]),
    _Group('Communications and reports', [
      'Prepare an accurate basic incident report.',
      'Communicate operational information using department procedures.',
    ]),
    _Group('Preincident and life-safety activities', [
      'Collect information for a basic preincident survey.',
      'Present basic fire and life-safety information to an assigned audience.',
    ]),
  ];

  static const _hazmatAwareness = <_Group>[
    _Group('Recognition and identification', [
      'Recognize clues that hazardous materials or WMD may be present without entering an unsafe area.',
      'Use approved references, markings, placards, labels, container clues, and occupancy information to identify likely hazards.',
    ]),
    _Group('Isolation and protective actions', [
      'Establish or support initial isolation and deny entry within the awareness-level role.',
      'Select basic protective-action information from approved emergency references and AHJ procedures.',
    ]),
    _Group('Notification and communication', [
      'Initiate required notifications and report location, observed clues, conditions, and known product/container information.',
      'Communicate changing hazards and observations to responding resources without exceeding the awareness-level role.',
    ]),
    _Group('Accountability and incident follow-up', [
      'Maintain personal and crew accountability while avoiding contamination or product contact.',
      'Complete required documentation, debriefing, and exposure reporting after the incident.',
    ]),
  ];

  static const _hazmatOperations = <_Group>[
    _Group('Analyze the incident', [
      'Identify containers, materials, release behavior, surrounding conditions, and likely harm using approved references.',
      'Recognize when conditions exceed operations-level capability and require technician or specialty resources.',
    ]),
    _Group('Plan the defensive response', [
      'Select defensive objectives, isolation/control zones, PPE limitations, and resource needs within the AHJ response plan.',
      'Identify decontamination needs and coordinate a safe operations-level work plan.',
    ]),
    _Group('Implement operations-level actions', [
      'Perform assigned defensive control, scene-control, and support actions within training and AHJ policy.',
      'Establish or support emergency decontamination and protect responders, the public, property, and environment.',
      'Use assigned PPE and monitoring equipment within the responder qualification held.',
    ]),
    _Group('Evaluate and communicate progress', [
      'Monitor conditions and response effectiveness and report meaningful changes.',
      'Adjust or recommend changes to defensive actions when hazards, resources, or incident objectives change.',
    ]),
    _Group('Termination and recovery', [
      'Assist with termination, equipment recovery, accountability, and documentation.',
      'Complete post-incident, exposure, medical-surveillance, and debrief requirements when applicable.',
    ]),
  ];

  static const _pumper = <_Group>[
    _Group('Apparatus inspection and readiness', [
      'Complete a documented apparatus inspection and identify deficiencies.',
      'Verify operational readiness of the vehicle, pump, tank, warning systems, and mounted equipment.',
    ]),
    _Group('Safe apparatus driving', [
      'Operate safely through routine road and traffic conditions.',
      'Demonstrate controlled backing, turning, stopping, and confined-space maneuvering.',
      'Apply emergency-response and defensive-driving policies.',
    ]),
    _Group('Pump engagement and discharge operations', [
      'Position the apparatus, engage the pump, and confirm pump mode safely.',
      'Supply attack lines at required flow/pressure while monitoring pump and intake conditions.',
      'Adjust operations as hose lines and incident demand change.',
    ]),
    _Group('Pressurized water supply', [
      'Establish and maintain hydrant-supplied pumping operations.',
      'Recognize water-supply limitations before cavitation or loss of supply.',
    ]),
    _Group('Static source and relay operations', [
      'Establish a draft from a static source and maintain stable supply.',
      'Participate in relay pumping and communicate pressure/flow changes.',
    ]),
    _Group('Foam and troubleshooting', [
      'Operate applicable foam-proportioning equipment when equipped or required.',
      'Recognize and correct common pumper operational problems within AHJ procedures.',
    ]),
  ];

  static const _emt = <_Group>[
    _Group('Scene size-up and safety', [
      'Identify scene hazards, use appropriate PPE, determine mechanism/nature of illness, and request needed resources.',
      'Apply infection-control, lifting/moving, responder-safety, and patient-access principles.',
    ]),
    _Group('Primary assessment', [
      'Form a general impression and rapidly identify immediate airway, breathing, circulation, disability, and exposure threats.',
      'Manage life threats with BLS interventions and determine transport priority.',
    ]),
    _Group('Secondary assessment and monitoring', [
      'Obtain a focused history and physical examination appropriate to the presentation.',
      'Measure, trend, and interpret basic vital signs and approved monitoring findings within EMT scope.',
    ]),
    _Group('Patient treatment and transport', [
      'Provide airway/ventilation, oxygenation, bleeding control, shock care, immobilization or movement, and other EMT-level treatment as indicated.',
      'Assist with or administer medications authorized at the EMT level by the jurisdiction and medical direction.',
      'Select an appropriate destination/transport priority and reassess after interventions or condition changes.',
    ]),
    _Group('Medical, trauma, and special populations', [
      'Recognize and manage common medical and behavioral emergencies within EMT scope.',
      'Recognize and manage common trauma presentations and time-critical injury patterns.',
      'Adapt assessment and care for pediatric, obstetric, geriatric, and special-needs patients.',
    ]),
    _Group('EMS operations, communication, and documentation', [
      'Give a clear radio/transfer report and complete accurate patient-care documentation.',
      'Apply consent, refusal, confidentiality, mandatory-reporting, evidence-preservation, and other EMS legal/ethical principles.',
      'Function safely within incident command, ambulance operations, multiple-patient incidents, and routine EMS systems.',
    ]),
  ];

  static const _aemt = <_Group>[
    _Group('Airway, respiration, and ventilation', [
      'Assess airway and respiratory failure and provide AEMT-level airway/ventilation management within local scope.',
      'Use authorized oxygenation, ventilation, airway adjunct, and monitoring strategies and reassess response.',
    ]),
    _Group('Cardiology and resuscitation', [
      'Recognize time-critical cardiovascular presentations and provide AEMT-level resuscitation care.',
      'Integrate high-quality CPR, AED/monitor use, vascular access, fluids, and authorized medications as indicated by protocol.',
    ]),
    _Group('Medical, obstetric, and gynecologic emergencies', [
      'Assess and manage common acute medical presentations using AEMT-level knowledge and authorized therapies.',
      'Manage pregnancy-related and obstetric emergencies within AEMT scope and identify high-risk findings.',
    ]),
    _Group('Trauma', [
      'Perform a prioritized trauma assessment and manage hemorrhage, shock, airway/ventilation, and transport needs.',
      'Integrate vascular access, fluid therapy, analgesia or other authorized AEMT interventions when indicated.',
    ]),
    _Group('Clinical judgment', [
      'Recognize and analyze patient cues, form a working impression, choose priorities, and reassess response to care.',
      'Modify the care plan when new findings, treatment response, or transport conditions change.',
    ]),
    _Group('EMS operations and professional practice', [
      'Communicate, document, and transfer care at the level expected of an AEMT.',
      'Apply safe ambulance/scene operations, medical-legal standards, teamwork, leadership, and resource coordination.',
    ]),
  ];

  static const _paramedic = <_Group>[
    _Group('Airway, respiration, and ventilation', [
      'Integrate anatomy, physiology, pathophysiology, assessment, and monitoring into an advanced airway/ventilation plan.',
      'Select, perform, verify, and reassess advanced airway and respiratory interventions within protocol and medical direction.',
    ]),
    _Group('Cardiology and resuscitation', [
      'Interpret clinical and ECG findings to recognize time-critical cardiovascular conditions and dysrhythmias.',
      'Provide guideline- and protocol-based resuscitation, electrical therapy, vascular access, and pharmacologic management.',
    ]),
    _Group('Medical, obstetric, and gynecologic emergencies', [
      'Build and refine a differential impression for complex acute medical presentations and treat within paramedic scope.',
      'Manage obstetric/gynecologic emergencies and high-risk pregnancy complications with appropriate maternal and neonatal priorities.',
    ]),
    _Group('Trauma', [
      'Integrate mechanism, physiology, examination, monitoring, and transport factors into trauma priorities.',
      'Manage airway, ventilation, hemorrhage, perfusion, pain, and other time-critical trauma problems within paramedic scope.',
    ]),
    _Group('Clinical judgment', [
      'Recognize and analyze cues, prioritize hypotheses, generate solutions, take action, and evaluate outcomes.',
      'Use reassessment, consultation, and changing scene/transport conditions to revise the treatment plan.',
    ]),
    _Group('Special populations', [
      'Adapt advanced assessment and treatment to pediatric, neonatal, obstetric, geriatric, behavioral, and special-needs patients.',
      'Recognize age- and condition-specific risks that alter medication, equipment, destination, or transport decisions.',
    ]),
    _Group('EMS operations, leadership, and professional practice', [
      'Lead team communication, task allocation, resource use, and transfer of care during routine and complex incidents.',
      'Complete defensible documentation and apply medical-legal, ethical, quality-improvement, safety, and system principles.',
    ]),
  ];

  static const _fi1 = <_Group>[
    _Group('Prepare for instruction', [
      'Review a prepared lesson plan and identify objectives, methods, materials, and evaluation.',
      'Prepare the learning environment, equipment, references, and instructional aids.',
      'Identify learner or environmental needs requiring an allowable lesson adjustment.',
    ]),
    _Group('Deliver prepared instruction', [
      'Present a prepared lesson using communication appropriate to the learners.',
      'Use instructional aids and equipment effectively and safely.',
      'Use questions, discussion, demonstrations, and practice to support objectives.',
      'Adapt delivery within the prepared lesson when learner needs change.',
    ]),
    _Group('Evaluate student performance', [
      'Administer a prepared written, oral, or performance evaluation consistently.',
      'Score student performance using the supplied evaluation instrument.',
      'Provide feedback and identify when remediation or referral is needed.',
    ]),
    _Group('Records and course closeout', [
      'Complete required attendance, evaluation, and training records accurately.',
      'Submit or secure course records according to AHJ policy.',
    ]),
  ];

  static const _fo1 = <_Group>[
    _Group('Human resource management', [
      'Assign work and communicate expected performance to unit members.',
      'Coach or counsel a member using policy and documented expectations.',
      'Address a company-level conflict or performance issue.',
      'Apply supervisory policy and agreements fairly.',
    ]),
    _Group('Community and government relations', [
      'Respond professionally to a citizen question or concern.',
      'Deliver or coordinate a public fire/life-safety message.',
    ]),
    _Group('Administration', [
      'Prepare a clear unit-level report or memorandum.',
      'Apply department policy to a routine administrative problem.',
      'Identify a unit need and communicate a request through the chain of command.',
    ]),
    _Group('Inspection and investigation', [
      'Conduct or support a basic occupancy inspection within assigned authority.',
      'Document hazards or code concerns and route them properly.',
      'Preserve observations that may support a fire-cause investigation.',
    ]),
    _Group('Emergency service delivery', [
      'Develop an initial action plan for a routine company-level emergency.',
      'Implement command, accountability, communications, and tactical priorities.',
      'Adjust the plan when conditions, hazards, or resources change.',
      'Participate in a post-incident review focused on improvement.',
    ]),
    _Group('Health and safety', [
      'Identify unsafe conditions or practices and take corrective action.',
      'Apply health, safety, exposure, and injury-reporting procedures.',
      'Promote crew readiness, rehabilitation, and risk-management practices.',
    ]),
  ];

  static const _fo2 = <_Group>[
    _Group('Supervision and personnel development', [
      'Evaluate subordinate performance and develop an improvement or development plan.',
      'Coordinate training based on identified organizational needs.',
      'Apply supervisory processes to a more complex personnel issue.',
    ]),
    _Group('Administration and budget', [
      'Prepare a program, project, or unit budget request with justification.',
      'Analyze records or operational data and prepare a management recommendation.',
      'Develop or revise a unit procedure consistent with policy.',
    ]),
    _Group('Community risk and inspections', [
      'Analyze an inspection, prevention, or community-risk issue and recommend action.',
      'Coordinate a public education or community-risk activity.',
    ]),
    _Group('Multi-unit emergency operations', [
      'Develop and communicate an incident plan for a multi-unit emergency.',
      'Manage resources and changing incident priorities within assigned command responsibility.',
      'Evaluate incident performance and document improvement actions.',
    ]),
    _Group('Organizational safety', [
      'Analyze a safety issue, near miss, injury, or exposure and recommend prevention.',
      'Evaluate unit compliance with safety policy and follow corrective action.',
    ]),
  ];

  static const _fo3 = <_Group>[
    _Group('Organizational leadership', [
      'Translate organizational goals into program or division objectives.',
      'Manage personnel and resources across multiple units or functions.',
      'Evaluate a program and recommend changes based on outcomes.',
    ]),
    _Group('Budget and resource management', [
      'Develop or manage a significant budget component.',
      'Evaluate resource allocation and present a management recommendation.',
    ]),
    _Group('Policy, planning, and community risk', [
      'Develop or evaluate policy for an organizational need.',
      'Use community or operational data to support a risk-reduction or service-delivery plan.',
      'Coordinate with external stakeholders on an organizational issue.',
    ]),
    _Group('Complex emergency management', [
      'Evaluate preparedness for a complex or expanding incident and identify gaps.',
      'Manage or evaluate command-level functions for complex emergency operations.',
    ]),
  ];

  static const _fo4 = <_Group>[
    _Group('Executive leadership and governance', [
      'Develop or evaluate organizational mission, goals, policy, and performance measures.',
      'Advise governing officials using evidence-based recommendations.',
      'Manage organizational change while considering workforce and community impacts.',
    ]),
    _Group('Strategic and financial management', [
      'Develop or evaluate a strategic plan tied to community needs and capability.',
      'Develop or defend an organizational budget and long-range resource strategy.',
      'Evaluate major programs, capital needs, or service-delivery alternatives.',
    ]),
    _Group('External relations and community risk', [
      'Build or evaluate partnerships with government, community, labor, and allied organizations.',
      'Communicate organizational risk, priorities, and performance to stakeholders.',
    ]),
    _Group('Organization-wide safety and continuity', [
      'Evaluate organization-wide safety, wellness, and risk-management performance.',
      'Plan for continuity, major emergencies, and organizational resilience.',
    ]),
  ];
}

class NationalTaskBookStandard {
  final String id;
  final String standard;
  final String edition;
  final String chapter;
  final List<RequirementPlanStep> steps;
  final List<RequirementSubTask> subTasks;

  const NationalTaskBookStandard({
    required this.id,
    required this.standard,
    required this.edition,
    required this.chapter,
    required this.steps,
    required this.subTasks,
  });

  String get citation => '$standard ($edition), $chapter';
}

class _Group {
  final String title;
  final List<String> items;
  const _Group(this.title, this.items);
}
