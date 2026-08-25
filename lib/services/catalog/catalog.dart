import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/certification_definition.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/resource.dart';

/// Stable catalog facade used across the app.
class FireOpsCatalog {
  FireOpsCatalog._();

  static const String otherStateCode = 'OTHER';

  static const List<String> commonRoles = <String>[
    'Firefighter',
    'Firefighter (Probationary)',
    'Driver/Operator',
    'Engineer',
    'Company Officer',
    'Lieutenant',
    'Captain',
    'Battalion Chief',
    'Division Chief',
    'Assistant Chief',
    'Deputy Chief',
    'Fire Chief',
    'Training Officer',
    'EMS Provider',
    'Wildland Firefighter',
    'Other (Custom)',
  ];

  static const List<String> commonCertifications = <String>[
    'Firefighter I',
    'Firefighter II',
    'HazMat Awareness',
    'HazMat Operations',
    'Driver/Operator – Pumper',
    'Incident Command (ICS 100/200)',
    'EMT',
    'AEMT',
    'Paramedic',
    'CPR / BLS',
    'EVOC',
  ];

  static final List<UsStateOption> usStateOptions = <UsStateOption>[
    ..._usStates,
    const UsStateOption(code: otherStateCode, name: 'Other / Outside US'),
  ];

  static String? stateNameForCode(String? code) {
    final c = code?.trim().toUpperCase();
    if (c == null || c.isEmpty) return null;
    return _stateNameByCode[c];
  }

  static String? stateCodeFromLegacyValue(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    final upper = v.toUpperCase();
    if (upper == otherStateCode) return otherStateCode;
    if (upper.length == 2 && _stateNameByCode.containsKey(upper)) return upper;
    final normalized = upper.replaceAll(RegExp(r'[^A-Z]+'), ' ').trim();
    if (normalized.isEmpty) return null;
    if (normalized == 'OTHER' || normalized == 'OUTSIDE US') return otherStateCode;
    return _stateCodeByName[normalized];
  }

  static String stateCodeFromLegacyValueOrOther(String? raw) =>
      stateCodeFromLegacyValue(raw) ?? otherStateCode;

  static List<CertificationDefinition> certificationDefinitions() => _certifications;
  static Map<String, CertificationDefinition> certificationById() => _certById;

  static String normalizeCertificationText(String value) {
    final v = value.toLowerCase().trim();
    if (v.isEmpty) return '';
    return v
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? matchCertificationDefinitionId(String input) {
    final n = normalizeCertificationText(input);
    if (n.isEmpty) return null;
    return _certMatchIndex[n];
  }

  static List<Resource> resources() => _resources;
  static List<CareerGoal> goals() => _goals;

  static void validateCatalog() {
    assert(() {
      final certIds = _certifications.map((e) => e.id).toList();
      final dupCert = _firstDuplicate(certIds);
      if (dupCert != null) {
        debugPrint('FireOpsCatalog: duplicate certification id: $dupCert');
      }
      final goalIds = _goals.map((e) => e.id).toList();
      final dupGoal = _firstDuplicate(goalIds);
      if (dupGoal != null) {
        debugPrint('FireOpsCatalog: duplicate goal id: $dupGoal');
      }
      return true;
    }());
  }

  static String? _firstDuplicate(List<String> values) {
    final seen = <String>{};
    for (final v in values) {
      if (!seen.add(v)) return v;
    }
    return null;
  }
}

@immutable
class UsStateOption {
  final String code;
  final String name;
  const UsStateOption({required this.code, required this.name});
}

final DateTime _seedNow = DateTime(2026, 8, 23);

CertificationDefinition _cert({
  required String id,
  required String displayName,
  String? shortName,
  required CertificationCategory category,
  required String description,
  List<String> aliases = const [],
  List<String> prerequisites = const [],
  List<String> recommendedPrerequisites = const [],
  bool typicallyExpires = false,
  int? typicalRenewalYears,
  bool stateDependent = true,
  bool nationalCredential = false,
  List<String> issuingOrganizations = const ['State fire authority / AHJ'],
  List<String> relatedCareerGoalIds = const [],
  List<String> resourceIds = const [],
  List<String> searchKeywords = const [],
  String? renewalDescription,
  String? continuingEducationNotes,
  List<String> renewalResourceIds = const [],
}) {
  return CertificationDefinition(
    id: id,
    displayName: displayName,
    shortName: shortName,
    category: category,
    description: description,
    aliases: aliases,
    prerequisiteCertificationIds: prerequisites,
    recommendedPrerequisiteIds: recommendedPrerequisites,
    typicallyExpires: typicallyExpires,
    typicalRenewalYears: typicalRenewalYears,
    stateDependent: stateDependent,
    nationalCredential: nationalCredential,
    issuingOrganizations: issuingOrganizations,
    relatedCareerGoalIds: relatedCareerGoalIds,
    resourceIds: resourceIds,
    searchKeywords: searchKeywords,
    renewalDescription: renewalDescription,
    continuingEducationNotes: continuingEducationNotes,
    renewalResourceIds: renewalResourceIds,
  );
}

final List<CertificationDefinition> _certifications = <CertificationDefinition>[
  _cert(
    id: 'firefighter_1',
    displayName: 'Firefighter I',
    shortName: 'FF1',
    category: CertificationCategory.firefighting,
    description: 'Entry-level structural firefighting certification (name varies by state/provider).',
    aliases: const ['Fire Fighter 1', 'Fire Fighter I', 'Firefighter 1'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    searchKeywords: const ['ff1', 'firefighter i', 'firefighter 1'],
  ),
  _cert(
    id: 'firefighter_2',
    displayName: 'Firefighter II',
    shortName: 'FF2',
    category: CertificationCategory.firefighting,
    description: 'Advanced structural firefighting certification (name varies by state/provider).',
    aliases: const ['Fire Fighter 2', 'Fire Fighter II', 'Firefighter 2'],
    prerequisites: const ['firefighter_1'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_engineer', 'ops_company_officer', 'ops_battalion_chief'],
    searchKeywords: const ['ff2', 'firefighter ii', 'firefighter 2'],
  ),
  _cert(
    id: 'hazmat_awareness',
    displayName: 'HazMat Awareness',
    shortName: 'HazMat Awareness',
    category: CertificationCategory.hazmat,
    description: 'Hazardous materials awareness-level training or certification. Requirements vary by state and AHJ.',
    aliases: const [
      'Hazmat Awareness',
      'Haz Mat Awareness',
      'Hazardous Materials Awareness',
      'HMA',
    ],
    relatedCareerGoalIds: const ['ops_firefighter'],
    searchKeywords: const ['hazmat awareness', 'haz mat awareness', 'hazardous materials awareness'],
  ),
  _cert(
    id: 'hazmat_operations',
    displayName: 'HazMat Operations',
    shortName: 'HazMat Ops',
    category: CertificationCategory.hazmat,
    description: 'Hazardous materials operations-level training or certification. Requirements vary by state and AHJ.',
    aliases: const [
      'Hazmat Operations',
      'Haz Mat Operations',
      'Hazardous Materials Operations',
      'HazMat Ops',
      'HMO',
    ],
    prerequisites: const ['hazmat_awareness'],
    relatedCareerGoalIds: const ['ops_firefighter'],
    searchKeywords: const ['hazmat operations', 'hazmat ops', 'haz mat operations', 'hazardous materials operations'],
  ),
  _cert(
    id: 'driver_operator_pumper',
    displayName: 'Driver/Operator – Pumper',
    shortName: 'D/O Pumper',
    category: CertificationCategory.driverOperator,
    description: 'Driver/operator (engine/pumper) certification or qualification. Requirements vary by state and department.',
    aliases: const ['Driver Operator Pumper', 'Engineer Pumper', 'Pump Operator'],
    prerequisites: const ['firefighter_1'],
    issuingOrganizations: const ['State fire authority / AHJ', 'Department'],
    relatedCareerGoalIds: const ['ops_engineer'],
    searchKeywords: const ['driver operator', 'pumper', 'engineer', 'pump operator'],
  ),
  _cert(
    id: 'emt',
    displayName: 'EMT',
    category: CertificationCategory.ems,
    description: 'Emergency Medical Technician credential (state/NREMT depending on jurisdiction).',
    aliases: const ['Emergency Medical Technician', 'NREMT EMT'],
    typicallyExpires: true,
    typicalRenewalYears: 2,
    nationalCredential: true,
    issuingOrganizations: const ['NREMT', 'State EMS office'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    searchKeywords: const ['emt', 'nremt'],
    renewalDescription: 'Renewal rules vary. Track your CE and follow your state/NREMT policy.',
    continuingEducationNotes: 'Confirm current CE hour distribution and skills verification rules for your state and NREMT.',
  ),
  _cert(
    id: 'aemt',
    displayName: 'AEMT',
    category: CertificationCategory.ems,
    description: 'Advanced EMT credential (state/NREMT depending on jurisdiction).',
    aliases: const ['Advanced EMT', 'NREMT AEMT'],
    prerequisites: const ['emt'],
    typicallyExpires: true,
    typicalRenewalYears: 2,
    nationalCredential: true,
    issuingOrganizations: const ['NREMT', 'State EMS office'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    searchKeywords: const ['aemt', 'advanced emt'],
    renewalDescription: 'Renewal rules vary. Track your CE and follow your state/NREMT policy.',
    continuingEducationNotes: 'Confirm current CE hour distribution and skills verification rules for your state and NREMT.',
  ),
  _cert(
    id: 'paramedic',
    displayName: 'Paramedic',
    category: CertificationCategory.ems,
    description: 'Paramedic credential (state/NREMT depending on jurisdiction).',
    aliases: const ['NREMT Paramedic'],
    prerequisites: const ['emt'],
    typicallyExpires: true,
    typicalRenewalYears: 2,
    nationalCredential: true,
    issuingOrganizations: const ['NREMT', 'State EMS office'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    searchKeywords: const ['paramedic', 'medic'],
    renewalDescription: 'Renewal rules vary. Track your CE and follow your state/NREMT policy.',
    continuingEducationNotes: 'Confirm current CE hour distribution and skills verification rules for your state and NREMT.',
  ),
  _cert(
    id: 'fire_officer_1',
    displayName: 'Fire Officer I',
    shortName: 'FO I',
    category: CertificationCategory.officer,
    description: 'Supervisory-level fire officer certification focused on company-level leadership, tactics, and daily operations (name and delivery vary by state / IFSAC / Pro Board).',
    aliases: const ['Fire Officer 1', 'Company Officer I', 'FO1', 'NFPA 1021 Fire Officer I'],
    prerequisites: const ['firefighter_2'],
    recommendedPrerequisites: const ['driver_operator_pumper'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_company_officer'],
    resourceIds: const ['state_fire_authority'],
    searchKeywords: const ['fire officer i', 'fire officer 1', 'fo1', 'company officer', 'nfpa 1021'],
  ),
  _cert(
    id: 'fire_officer_2',
    displayName: 'Fire Officer II',
    shortName: 'FO II',
    category: CertificationCategory.officer,
    description: 'Mid-level fire officer certification covering multi-company supervision, planning, and administrative responsibilities (varies by state / IFSAC / Pro Board).',
    aliases: const ['Fire Officer 2', 'FO2', 'NFPA 1021 Fire Officer II'],
    prerequisites: const ['fire_officer_1'],
    recommendedPrerequisites: const ['fire_instructor_1'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_company_officer', 'ops_battalion_chief'],
    resourceIds: const ['state_fire_authority'],
    searchKeywords: const ['fire officer ii', 'fire officer 2', 'fo2', 'nfpa 1021'],
  ),
  _cert(
    id: 'fire_officer_3',
    displayName: 'Fire Officer III',
    shortName: 'FO III',
    category: CertificationCategory.officer,
    description: 'Senior / administrative fire officer certification emphasizing program management, interagency coordination, and organizational leadership.',
    aliases: const ['Fire Officer 3', 'FO3', 'NFPA 1021 Fire Officer III'],
    prerequisites: const ['fire_officer_2'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_battalion_chief', 'ops_division_chief'],
    resourceIds: const ['state_fire_authority'],
    searchKeywords: const ['fire officer iii', 'fire officer 3', 'fo3', 'nfpa 1021'],
  ),
  _cert(
    id: 'fire_officer_4',
    displayName: 'Fire Officer IV',
    shortName: 'FO IV',
    category: CertificationCategory.officer,
    description: 'Executive-level fire officer certification focused on strategic leadership, policy, and department-level administration.',
    aliases: const ['Fire Officer 4', 'FO4', 'NFPA 1021 Fire Officer IV', 'Executive Fire Officer'],
    prerequisites: const ['fire_officer_3'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)', 'National Fire Academy (related executive programs)'],
    relatedCareerGoalIds: const ['ops_division_chief', 'ops_deputy_chief', 'ops_fire_chief'],
    resourceIds: const ['state_fire_authority'],
    searchKeywords: const ['fire officer iv', 'fire officer 4', 'fo4', 'executive fire officer', 'nfpa 1021'],
  ),
  _cert(
    id: 'fire_instructor_1',
    displayName: 'Fire Instructor I',
    shortName: 'FI I',
    category: CertificationCategory.instructor,
    description: 'Entry-level fire service instructor certification for delivering organized training and evaluating student performance (NFPA 1041 level I equivalent in many systems).',
    aliases: const ['Fire Instructor 1', 'Instructor I', 'FI1', 'NFPA 1041 Fire Instructor I'],
    prerequisites: const ['firefighter_2'],
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_company_officer', 'ops_battalion_chief'],
    resourceIds: const ['state_fire_authority'],
    searchKeywords: const ['fire instructor i', 'fire instructor 1', 'fi1', 'instructor i', 'nfpa 1041'],
  ),
];

final Map<String, CertificationDefinition> _certById = {
  for (final d in _certifications) d.id: d,
};

final Map<String, String> _certMatchIndex = () {
  final out = <String, String>{};
  void add(String key, String id) {
    final n = FireOpsCatalog.normalizeCertificationText(key);
    if (n.isNotEmpty) out.putIfAbsent(n, () => id);
  }

  for (final d in _certifications) {
    add(d.displayName, d.id);
    if (d.shortName != null) add(d.shortName!, d.id);
    for (final a in d.aliases) add(a, d.id);
    for (final kw in d.searchKeywords) add(kw, d.id);
  }

  add('ff i', 'firefighter_1');
  add('ff 1', 'firefighter_1');
  add('ff ii', 'firefighter_2');
  add('ff 2', 'firefighter_2');
  add('haz awareness', 'hazmat_awareness');
  add('hazmat awareness', 'hazmat_awareness');
  add('haz mat awareness', 'hazmat_awareness');
  add('haz ops', 'hazmat_operations');
  add('hazmat ops', 'hazmat_operations');
  add('haz mat ops', 'hazmat_operations');
  add('do pumper', 'driver_operator_pumper');
  add('driver operator', 'driver_operator_pumper');
  add('pump ops', 'driver_operator_pumper');
  add('fo i', 'fire_officer_1');
  add('fo 1', 'fire_officer_1');
  add('fo1', 'fire_officer_1');
  add('fo ii', 'fire_officer_2');
  add('fo 2', 'fire_officer_2');
  add('fo2', 'fire_officer_2');
  add('fo iii', 'fire_officer_3');
  add('fo 3', 'fire_officer_3');
  add('fo3', 'fire_officer_3');
  add('fo iv', 'fire_officer_4');
  add('fo 4', 'fire_officer_4');
  add('fo4', 'fire_officer_4');
  add('fi i', 'fire_instructor_1');
  add('fi 1', 'fire_instructor_1');
  add('fi1', 'fire_instructor_1');
  add('instructor i', 'fire_instructor_1');
  return out;
}();

final List<Resource> _resources = <Resource>[
  Resource(
    id: 'state_fire_authority',
    title: 'Your state fire certification authority',
    description: 'Find the official source for your state’s firefighter training and certification requirements.',
    type: ResourceType.officialStateAgency,
    url: null,
    state: null,
    relatedCertificationDefinitionIds: const [],
    relatedCareerGoalIds: const [],
    verified: true,
    lastVerifiedDate: _seedNow,
    sourceType: ResourceSourceType.official,
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
];

final List<CareerGoal> _goals = <CareerGoal>[
  CareerGoal(
    id: 'ops_firefighter',
    title: 'Firefighter',
    category: 'Operations',
    description: 'Build a solid baseline for structural firefighting readiness.',
    subtitle: 'Core certs + foundational training',
    typicalPrerequisiteRoles: const ['Firefighter (Probationary)', 'Volunteer Firefighter'],
    requirements: <Requirement>[
      _reqCert('ff1', 'Firefighter I', defId: 'firefighter_1', sortOrder: 10, stateDependent: true),
      _reqCert('haz_awareness', 'HazMat Awareness', defId: 'hazmat_awareness', sortOrder: 20, stateDependent: true),
      _reqCert('haz_ops', 'HazMat Operations', defId: 'hazmat_operations', sortOrder: 30, stateDependent: true),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Driver/Operator', 'Engineer'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ops_engineer',
    title: 'Driver/Operator / Engineer',
    category: 'Operations',
    description: 'Prepare for driving, pumping, and apparatus operations expectations.',
    subtitle: 'Pump ops + apparatus readiness',
    typicalPrerequisiteRoles: const ['Firefighter'],
    requirements: <Requirement>[
      _reqCert('ff2', 'Firefighter II', defId: 'firefighter_2', sortOrder: 10, stateDependent: true),
      _reqCert('do_pumper', 'Driver/Operator – Pumper', defId: 'driver_operator_pumper', sortOrder: 20, stateDependent: true),
      _reqCourse('state_driver_policy', 'State driver/operator policy check', sortOrder: 30, stateDependent: true, description: 'Confirm your state’s current driver/operator training and certification policy, then confirm your department SOPs.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Company Officer', 'Lieutenant', 'Captain'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ops_company_officer',
    title: 'Company Officer',
    category: 'Operations',
    description: 'Prepare to lead a company: tactics, people, training, and daily readiness.',
    subtitle: 'Lieutenant / Captain track',
    typicalPrerequisiteRoles: const ['Driver/Operator', 'Engineer', 'Firefighter'],
    requirements: <Requirement>[
      _reqCert('fo1', 'Fire Officer I', defId: 'fire_officer_1', sortOrder: 10, stateDependent: true),
      _reqCert('fi1', 'Fire Instructor I', defId: 'fire_instructor_1', sortOrder: 20, stateDependent: true),
      _reqCourse('ics300', 'ICS 300', sortOrder: 30, description: 'Intermediate ICS for expanding incidents and supervisory roles.'),
      _reqCourse('acting_time', 'Documented acting / ride-up time', sortOrder: 40, description: 'Log supervised company-level acting assignments and feedback.'),
      _reqCourse('promo_prep_co', 'Company officer promotional prep', sortOrder: 50, description: 'Written, assessment center, and interview preparation for company officer.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Battalion Chief', 'Captain'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ops_battalion_chief',
    title: 'Battalion Chief',
    category: 'Operations',
    description: 'Multi-company command, shift leadership, and operational oversight.',
    subtitle: 'Shift / battalion command',
    typicalPrerequisiteRoles: const ['Company Officer', 'Captain', 'Lieutenant'],
    requirements: <Requirement>[
      _reqCert('fo2', 'Fire Officer II', defId: 'fire_officer_2', sortOrder: 10, stateDependent: true),
      _reqCourse('ics400', 'ICS 400', sortOrder: 20, description: 'Advanced ICS for complex incident management and area command concepts.'),
      _reqCourse('multi_company', 'Multi-company / shift command experience', sortOrder: 30, description: 'Documented command of multi-unit responses and shift-level leadership.'),
      _reqCourse('promo_prep_bc', 'Battalion chief promotional prep', sortOrder: 40, description: 'Assessment, command scenarios, and interview preparation.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Division Chief', 'Assistant Chief', 'Deputy Chief'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ops_division_chief',
    title: 'Division / Assistant Chief',
    category: 'Operations',
    description: 'Program leadership, planning, and department-level operational support.',
    subtitle: 'Senior staff / division leadership',
    typicalPrerequisiteRoles: const ['Battalion Chief', 'Captain'],
    requirements: <Requirement>[
      _reqCert('fo3', 'Fire Officer III', defId: 'fire_officer_3', sortOrder: 10, stateDependent: true),
      _reqCourse('exec_dev', 'Executive / senior officer development', sortOrder: 20, description: 'Leadership, labor, budget, and strategic planning coursework or program.'),
      _reqCourse('program_ownership', 'Major program or division ownership', sortOrder: 30, description: 'Documented ownership of training, ops, EMS, prevention, or similar major program.'),
      _reqCourse('promo_prep_ac', 'Senior chief promotional prep', sortOrder: 40, description: 'Executive interview, strategic scenarios, and portfolio preparation.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Deputy Chief', 'Fire Chief'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ops_deputy_chief',
    title: 'Deputy Chief',
    category: 'Operations',
    description: 'Second-in-command readiness: citywide operations, labor, and executive support.',
    subtitle: 'Executive operations leadership',
    typicalPrerequisiteRoles: const ['Division Chief', 'Assistant Chief', 'Battalion Chief'],
    requirements: <Requirement>[
      _reqCert('fo4', 'Fire Officer IV', defId: 'fire_officer_4', sortOrder: 10, stateDependent: true),
      _reqCourse('citywide_ops', 'Citywide / department operations leadership', sortOrder: 20, description: 'Evidence of department-level operational decision-making and coverage planning.'),
      _reqCourse('labor_budget', 'Labor, budget, or policy exposure', sortOrder: 30, description: 'Documented involvement in budget, labor relations, policy, or city processes.'),
      _reqCourse('promo_prep_dc', 'Deputy chief / executive prep', sortOrder: 40, description: 'Executive assessment and interview preparation.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Fire Chief'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ops_fire_chief',
    title: 'Fire Chief',
    category: 'Operations',
    description: 'Prepare for the top executive role: strategy, culture, risk, and community leadership.',
    subtitle: 'Department executive',
    typicalPrerequisiteRoles: const ['Deputy Chief', 'Assistant Chief', 'Division Chief'],
    requirements: <Requirement>[
      _reqCert('fo4_chief', 'Fire Officer IV / Executive pathway', defId: 'fire_officer_4', sortOrder: 10, stateDependent: true),
      _reqCourse('strategic_plan', 'Strategic plan / CRR leadership', sortOrder: 20, description: 'Evidence of strategic planning, community risk reduction, or equivalent executive work.'),
      _reqCourse('external_relations', 'City / board / community leadership', sortOrder: 30, description: 'Documented work with elected officials, boards, mutual aid, or community partners.'),
      _reqCourse('chief_promo_prep', 'Fire chief selection prep', sortOrder: 40, description: 'Executive interview, portfolio, and assessment preparation for fire chief processes.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const [],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
];

Requirement _reqCert(
  String id,
  String name, {
  required int sortOrder,
  String? defId,
  bool stateDependent = false,
  bool allowExpired = false,
}) {
  return Requirement(
    id: id,
    name: name,
    category: 'Certification',
    priority: RequirementPriority.core,
    description: 'Track completion and renewal details in Certs.',
    type: RequirementType.certification,
    requirementSource: RequirementSource.commonlyRequired,
    defaultRequired: true,
    stateDependent: stateDependent,
    departmentDependent: false,
    completed: false,
    progressCurrent: null,
    progressRequired: null,
    progressUnit: null,
    experienceValue: null,
    experienceUnit: null,
    certificationReference: name,
    certificationDefinitionId: defId,
    allowExpiredCertification: allowExpired,
    prerequisiteRequirementIds: const [],
    resourceIds: const [],
    resourceLinks: const [],
    sortOrder: sortOrder,
    estimatedDurationDays: null,
    recommendedLeadTimeDays: null,
    canRunConcurrent: true,
    timelineCategory: TimelineCategory.certification,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: _seedNow,
    updatedAt: _seedNow,
  );
}

Requirement _reqCourse(
  String id,
  String name, {
  required int sortOrder,
  required String description,
  bool stateDependent = false,
}) {
  return Requirement(
    id: id,
    name: name,
    category: 'Training',
    priority: RequirementPriority.recommended,
    description: description,
    type: RequirementType.trainingCourse,
    requirementSource: RequirementSource.recommended,
    defaultRequired: true,
    stateDependent: stateDependent,
    departmentDependent: false,
    completed: false,
    progressCurrent: null,
    progressRequired: null,
    progressUnit: null,
    experienceValue: null,
    experienceUnit: null,
    certificationReference: null,
    certificationDefinitionId: null,
    allowExpiredCertification: false,
    prerequisiteRequirementIds: const [],
    resourceIds: const [],
    resourceLinks: const [],
    sortOrder: sortOrder,
    estimatedDurationDays: null,
    recommendedLeadTimeDays: null,
    canRunConcurrent: true,
    timelineCategory: TimelineCategory.course,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: _seedNow,
    updatedAt: _seedNow,
  );
}

const List<UsStateOption> _usStates = <UsStateOption>[
  UsStateOption(code: 'AL', name: 'Alabama'),
  UsStateOption(code: 'AK', name: 'Alaska'),
  UsStateOption(code: 'AZ', name: 'Arizona'),
  UsStateOption(code: 'AR', name: 'Arkansas'),
  UsStateOption(code: 'CA', name: 'California'),
  UsStateOption(code: 'CO', name: 'Colorado'),
  UsStateOption(code: 'CT', name: 'Connecticut'),
  UsStateOption(code: 'DE', name: 'Delaware'),
  UsStateOption(code: 'DC', name: 'District of Columbia'),
  UsStateOption(code: 'FL', name: 'Florida'),
  UsStateOption(code: 'GA', name: 'Georgia'),
  UsStateOption(code: 'HI', name: 'Hawaii'),
  UsStateOption(code: 'ID', name: 'Idaho'),
  UsStateOption(code: 'IL', name: 'Illinois'),
  UsStateOption(code: 'IN', name: 'Indiana'),
  UsStateOption(code: 'IA', name: 'Iowa'),
  UsStateOption(code: 'KS', name: 'Kansas'),
  UsStateOption(code: 'KY', name: 'Kentucky'),
  UsStateOption(code: 'LA', name: 'Louisiana'),
  UsStateOption(code: 'ME', name: 'Maine'),
  UsStateOption(code: 'MD', name: 'Maryland'),
  UsStateOption(code: 'MA', name: 'Massachusetts'),
  UsStateOption(code: 'MI', name: 'Michigan'),
  UsStateOption(code: 'MN', name: 'Minnesota'),
  UsStateOption(code: 'MS', name: 'Mississippi'),
  UsStateOption(code: 'MO', name: 'Missouri'),
  UsStateOption(code: 'MT', name: 'Montana'),
  UsStateOption(code: 'NE', name: 'Nebraska'),
  UsStateOption(code: 'NV', name: 'Nevada'),
  UsStateOption(code: 'NH', name: 'New Hampshire'),
  UsStateOption(code: 'NJ', name: 'New Jersey'),
  UsStateOption(code: 'NM', name: 'New Mexico'),
  UsStateOption(code: 'NY', name: 'New York'),
  UsStateOption(code: 'NC', name: 'North Carolina'),
  UsStateOption(code: 'ND', name: 'North Dakota'),
  UsStateOption(code: 'OH', name: 'Ohio'),
  UsStateOption(code: 'OK', name: 'Oklahoma'),
  UsStateOption(code: 'OR', name: 'Oregon'),
  UsStateOption(code: 'PA', name: 'Pennsylvania'),
  UsStateOption(code: 'RI', name: 'Rhode Island'),
  UsStateOption(code: 'SC', name: 'South Carolina'),
  UsStateOption(code: 'SD', name: 'South Dakota'),
  UsStateOption(code: 'TN', name: 'Tennessee'),
  UsStateOption(code: 'TX', name: 'Texas'),
  UsStateOption(code: 'UT', name: 'Utah'),
  UsStateOption(code: 'VT', name: 'Vermont'),
  UsStateOption(code: 'VA', name: 'Virginia'),
  UsStateOption(code: 'WA', name: 'Washington'),
  UsStateOption(code: 'WV', name: 'West Virginia'),
  UsStateOption(code: 'WI', name: 'Wisconsin'),
  UsStateOption(code: 'WY', name: 'Wyoming'),
];

final Map<String, String> _stateNameByCode = {
  for (final s in _usStates) s.code: s.name,
  FireOpsCatalog.otherStateCode: 'Other / Outside US',
};

final Map<String, String> _stateCodeByName = () {
  final out = <String, String>{};
  for (final s in _usStates) {
    out[s.name.toUpperCase()] = s.code;
  }
  out['DISTRICT OF COLUMBIA'] = 'DC';
  out['WASHINGTON DC'] = 'DC';
  out['WASHINGTON D C'] = 'DC';
  out['D C'] = 'DC';
  out['DC'] = 'DC';
  return out;
}();
