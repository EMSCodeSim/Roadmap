import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_path.dart';
import 'package:firepath/models/certification_definition.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/resource.dart';

/// Stable catalog facade used across the app.
class FireOpsCatalog {
  FireOpsCatalog._();

  static const String otherStateCode = 'OTHER';

  /// Fire operations roles shown during Personal setup.
  static const List<String> fireRoles = <String>[
    'Recruit / Probationary',
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
    'Wildland Firefighter',
    'Other (Custom)',
  ];

  /// EMS career roles shown during Personal setup.
  static const List<String> emsRoles = <String>[
    'EMS Explorer / Student',
    'EMT Student',
    'EMT',
    'Advanced EMT',
    'Paramedic',
    'Experienced Paramedic',
    'FTO / Preceptor',
    'EMS Instructor',
    'EMS Supervisor',
    'EMS Lieutenant',
    'EMS Captain',
    'EMS Chief / Director',
    'Other (Custom)',
  ];

  /// Combined list kept for back-compat callers.
  static const List<String> commonRoles = <String>[
    'Recruit / Probationary',
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
    'EMS Explorer / Student',
    'EMT Student',
    'EMT',
    'Advanced EMT',
    'Paramedic',
    'Experienced Paramedic',
    'FTO / Preceptor',
    'EMS Instructor',
    'EMS Supervisor',
    'EMS Lieutenant',
    'EMS Captain',
    'EMS Chief / Director',
    'Wildland Firefighter',
    'Other (Custom)',
  ];

  static const List<String> fireCertifications = <String>[
    'Firefighter I',
    'Firefighter II',
    'HazMat Awareness',
    'HazMat Operations',
    'Driver/Operator – Pumper',
    'Incident Command (ICS 100/200)',
    'Fire Officer I',
    'Fire Instructor I',
    'CPR / BLS',
    'EVOC',
  ];

  static const List<String> emsCertifications = <String>[
    'EMT',
    'AEMT',
    'Paramedic',
    'CPR / BLS',
    'EVOC',
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

  /// Recommended visible Fire career-stage sequence.
  ///
  /// This is intentionally more granular than [fireOperationsLadder]. Multiple
  /// visible stages can share one requirement bundle. Users may customize this
  /// sequence in Personal Roadmap without changing Department Mode ranks.
  static const List<String> fireCareerStages = <String>[
    'Recruit',
    'Probationary Firefighter',
    'Firefighter',
    'Driver/Operator',
    'Engineer',
    'Lieutenant',
    'Captain',
    'Battalion Chief',
    'Division Chief',
    'Assistant Chief',
    'Deputy Chief',
    'Fire Chief',
  ];

  /// Specialty qualifications stay outside the straight promotion ladder.
  static const List<String> fireSpecialtyQualifications = <String>[
    'Driver Trainee',
    'Acting Officer',
    'Company Officer Qualification',
    'Instructor',
    'Training Officer',
    'Wildland Firefighter',
    'HazMat',
    'Technical Rescue',
    'Investigator',
    'Medic',
  ];

  /// Maps a visible stage to the cumulative requirement bundle it belongs to.
  ///
  /// Unknown/custom replacement labels intentionally return null. This lets a
  /// user replace a default stage and then add department-specific requirements
  /// without silently inheriting requirements from a rank they do not use.
  static String? fireGoalIdForStageLabel(String label) {
    return switch (label.trim().toLowerCase()) {
      'recruit' || 'recruit / probationary' || 'probationary firefighter' || 'firefighter' => 'ops_firefighter',
      'driver/operator' || 'driver operator' || 'engineer' => 'ops_engineer',
      'company officer' || 'lieutenant' || 'captain' => 'ops_company_officer',
      'battalion chief' => 'ops_battalion_chief',
      'division chief' || 'assistant chief' => 'ops_division_chief',
      'deputy chief' => 'ops_deputy_chief',
      'fire chief' => 'ops_fire_chief',
      _ => null,
    };
  }

  /// Cumulative Fire operations requirement bundles used by [ProfileController].
  static const List<String> fireOperationsLadder = <String>[
    'ops_firefighter',
    'ops_engineer',
    'ops_company_officer',
    'ops_battalion_chief',
    'ops_division_chief',
    'ops_deputy_chief',
    'ops_fire_chief',
  ];

  /// Cumulative EMS clinician → leadership ladder.
  ///
  /// Specialty goals (Critical Care, Community Paramedicine, etc.) stay off
  /// this list so they remain single-stage branches that can grow later.
  static const List<String> emsCareerLadder = <String>[
    'ems_explorer',
    'ems_emt_student',
    'ems_emt',
    'ems_aemt',
    'ems_paramedic',
    'ems_experienced_paramedic',
    'ems_fto',
    'ems_instructor',
    'ems_supervisor',
    'ems_captain',
    'ems_chief',
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

  static List<CareerGoal> goalsForPath(CareerPath path) {
    switch (path) {
      case CareerPath.fire:
        return _goals.where(_isFireGoal).toList();
      case CareerPath.ems:
        return _goals.where(_isEmsGoal).toList();
      case CareerPath.both:
        return List<CareerGoal>.from(_goals);
    }
  }

  static List<String> rolesForPath(CareerPath path) {
    switch (path) {
      case CareerPath.fire:
        return fireRoles;
      case CareerPath.ems:
        return emsRoles;
      case CareerPath.both:
        // Fire first, then EMS titles not already present.
        final seen = <String>{};
        final out = <String>[];
        for (final role in [...fireRoles, ...emsRoles]) {
          if (role == 'Other (Custom)') continue;
          if (seen.add(role)) out.add(role);
        }
        out.add('Other (Custom)');
        return out;
    }
  }

  static List<String> certificationsForPath(CareerPath path) {
    switch (path) {
      case CareerPath.fire:
        return fireCertifications;
      case CareerPath.ems:
        return emsCertifications;
      case CareerPath.both:
        final seen = <String>{};
        final out = <String>[];
        for (final cert in [...fireCertifications, ...emsCertifications]) {
          if (seen.add(cert)) out.add(cert);
        }
        return out;
    }
  }

  /// Ladder IDs for a goal, if it sits on a cumulative Personal path.
  static List<String>? ladderContaining(String goalId) {
    if (fireOperationsLadder.contains(goalId)) return fireOperationsLadder;
    if (emsCareerLadder.contains(goalId)) return emsCareerLadder;
    return null;
  }

  static bool _isFireGoal(CareerGoal goal) =>
      goal.id.startsWith('ops_') ||
      goal.category == 'Operations' ||
      goal.category == 'Fire Specialty';

  static bool _isEmsGoal(CareerGoal goal) =>
      goal.id.startsWith('ems_') ||
      goal.category == 'EMS' ||
      goal.category == 'EMS Specialty';

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
    relatedCareerGoalIds: const [
      'ops_firefighter',
      'ops_engineer',
      'ems_emt',
      'ems_aemt',
      'ems_paramedic',
    ],
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
    relatedCareerGoalIds: const [
      'ops_firefighter',
      'ops_engineer',
      'ems_aemt',
      'ems_paramedic',
    ],
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
    relatedCareerGoalIds: const [
      'ops_firefighter',
      'ops_engineer',
      'ems_paramedic',
      'ems_experienced_paramedic',
      'ems_fto',
      'ems_specialty_critical_care',
    ],
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
    for (final a in d.aliases) {
      add(a, d.id);
    }
    for (final kw in d.searchKeywords) {
      add(kw, d.id);
    }
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
  Resource(
    id: 'nwcg_fft2',
    title: 'NWCG Firefighter Type 2 (FFT2) qualification requirements',
    description: 'Official NWCG training, fitness, and qualification requirements for Firefighter Type 2 (Crewmember).',
    type: ResourceType.officialStateAgency,
    url: 'https://www.nwcg.gov/positions/firefighter-type-2-crewmember/qualification-requirements',
    state: null,
    relatedCertificationDefinitionIds: const [],
    relatedCareerGoalIds: const ['wildland_fft2'],
    verified: true,
    lastVerifiedDate: _seedNow,
    sourceType: ResourceSourceType.official,
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  Resource(
    id: 'state_ems_authority',
    title: 'Your state EMS office',
    description: 'Find the official source for EMT/AEMT/Paramedic certification, CE, and scope-of-practice rules.',
    type: ResourceType.officialStateAgency,
    url: null,
    state: null,
    relatedCertificationDefinitionIds: const ['emt', 'aemt', 'paramedic'],
    relatedCareerGoalIds: const [
      'ems_emt',
      'ems_aemt',
      'ems_paramedic',
      'ems_experienced_paramedic',
    ],
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
      _reqCourse(
        'recruit_orientation',
        'Department orientation and safety',
        sortOrder: 10,
        description: 'Complete department orientation, code of conduct, reporting expectations, accountability, injury/exposure reporting, and core safety policies.',
      ),
      _reqCourse(
        'cpr_bls',
        'CPR / BLS',
        sortOrder: 20,
        description: 'Maintain a current CPR/BLS credential appropriate for your department and response role.',
      ),
      _reqCourse(
        'ics100',
        'ICS 100',
        sortOrder: 30,
        description: 'Complete introductory Incident Command System training before operating within the incident command structure.',
      ),
      _reqCourse(
        'nims700',
        'NIMS IS-700',
        sortOrder: 40,
        description: 'Complete the introductory National Incident Management System course or your department’s current equivalent.',
      ),
      _reqCourse(
        'ics200',
        'ICS 200',
        sortOrder: 50,
        description: 'Complete basic ICS training for initial-response incidents and common supervisory concepts.',
      ),
      _reqCourse(
        'nims800',
        'NIMS IS-800',
        sortOrder: 60,
        description: 'Complete National Response Framework awareness training or your department’s current equivalent.',
      ),
      _reqCourse(
        'ppe_scba',
        'PPE and SCBA competency',
        sortOrder: 70,
        description: 'Demonstrate inspection, donning, emergency procedures, air management, and safe operation in structural firefighting PPE and SCBA.',
      ),
      _reqCourse(
        'radio_accountability',
        'Radio communications and accountability',
        sortOrder: 80,
        description: 'Demonstrate department radio use, clear fireground communications, PAR/accountability procedures, emergency traffic, and MAYDAY fundamentals.',
      ),
      _reqCourse(
        'apparatus_tools',
        'Apparatus and equipment orientation',
        sortOrder: 90,
        description: 'Locate and identify commonly used apparatus equipment, hand tools, hose, appliances, ladders, forcible-entry tools, and basic EMS equipment.',
      ),
      _reqCourse(
        'hose_nozzle',
        'Hose, nozzle, and water application skills',
        sortOrder: 100,
        description: 'Demonstrate hose deployment, coupling, advancement, nozzle patterns, basic stream selection, and coordinated water application.',
      ),
      _reqCourse(
        'ground_ladders',
        'Ground ladder competency',
        sortOrder: 110,
        description: 'Demonstrate safe carries, raises, placement, climbing, leg locks, and common ladder operations used by the department.',
      ),
      _reqCourse(
        'forcible_entry_vent',
        'Forcible entry and ventilation fundamentals',
        sortOrder: 120,
        description: 'Demonstrate safe basic forcible-entry methods, tool selection, door control, and ventilation concepts within department policy.',
      ),
      _reqCourse(
        'search_rescue',
        'Search, rescue, and victim removal',
        sortOrder: 130,
        description: 'Demonstrate oriented search, team integrity, victim removal, firefighter survival awareness, and communication during interior operations.',
      ),
      _reqCourse(
        'fire_behavior',
        'Fire behavior and building construction',
        sortOrder: 140,
        description: 'Demonstrate foundational recognition of fire development, flow path, smoke indicators, structural hazards, and common construction features.',
      ),
      _reqCert('ff1', 'Firefighter I', defId: 'firefighter_1', sortOrder: 150, stateDependent: true),
      _reqCert('haz_awareness', 'HazMat Awareness', defId: 'hazmat_awareness', sortOrder: 160, stateDependent: true),
      _reqCert('haz_ops', 'HazMat Operations', defId: 'hazmat_operations', sortOrder: 170, stateDependent: true),
      _reqCourse(
        'probationary_signoff',
        'Probationary / recruit task book sign-off',
        sortOrder: 180,
        description: 'Complete the department’s probationary or recruit task book, local skills checks, station expectations, and required evaluator sign-offs.',
      ),
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
      _reqCourse('driver_prereq_review', 'Driver qualification prerequisites review', sortOrder: 20, description: 'Confirm license, driving-record, age/experience, medical, insurance, and department prerequisites before beginning apparatus qualification.'),
      _reqCourse('evoc', 'Emergency vehicle operations / EVOC', sortOrder: 30, stateDependent: true, description: 'Complete the emergency vehicle operations course or department-approved equivalent required for apparatus response driving.'),
      _reqCourse('apparatus_inspection', 'Apparatus inspection and deficiency reporting', sortOrder: 40, description: 'Perform documented daily/weekly apparatus checks, identify deficiencies, and follow the department reporting process.'),
      _reqCourse('backing_spotting', 'Backing, spotting, and cone-course skills', sortOrder: 50, description: 'Demonstrate controlled backing, spotter communication, turning, positioning, clearance judgment, and department cone-course skills.'),
      _reqCourse('response_driving', 'Supervised response driving', sortOrder: 60, description: 'Complete supervised non-emergent and emergent driving experience with evaluator documentation before independent release.'),
      _reqCourse('district_familiarization', 'District and response-area familiarization', sortOrder: 70, description: 'Demonstrate knowledge of major streets, target hazards, water-supply limitations, first-due considerations, and common response routes.'),
      _reqCourse('water_supply', 'Water supply and hydrant operations', sortOrder: 80, description: 'Demonstrate hydrant connections, forward/reverse lays, relay concepts, static sources where applicable, and coordinated water supply operations.'),
      _reqCourse('pump_hydraulics', 'Pump hydraulics and pressure calculations', sortOrder: 90, description: 'Demonstrate friction loss, appliance/elevation considerations, nozzle pressure, pump discharge pressure, and department pump charts or calculators.'),
      _reqCourse('pump_operations', 'Practical pump operations', sortOrder: 100, description: 'Demonstrate engagement, tank-to-pump, hydrant supply, multiple handlines, master streams, troubleshooting, and safe shutdown procedures.'),
      _reqCert('do_pumper', 'Driver/Operator – Pumper', defId: 'driver_operator_pumper', sortOrder: 110, stateDependent: true),
      _reqCourse('state_driver_policy', 'State driver/operator policy check', sortOrder: 120, stateDependent: true, description: 'Confirm your state’s current driver/operator training and certification policy, then confirm your department SOPs.'),
      _reqCourse('driver_release', 'Department driver/operator release', sortOrder: 130, description: 'Complete department evaluator sign-offs and final authorization for the apparatus or role you are qualifying on.'),
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
      _reqCourse('officer_readiness_review', 'Officer readiness and prerequisites review', sortOrder: 10, description: 'Confirm department time-in-grade, certification, education, acting, and promotional prerequisites for the company-officer path.'),
      _reqCert('fo1', 'Fire Officer I', defId: 'fire_officer_1', sortOrder: 20, stateDependent: true),
      _reqCert('fi1', 'Fire Instructor I', defId: 'fire_instructor_1', sortOrder: 30, stateDependent: true),
      _reqCourse('ics300', 'ICS 300', sortOrder: 40, description: 'Intermediate ICS for expanding incidents and supervisory roles.'),
      _reqCourse('company_sizeup', 'Company-level size-up and tactical decision-making', sortOrder: 50, description: 'Demonstrate initial size-up, strategy/tactics selection, risk assessment, command transfer, and crew assignment within department policy.'),
      _reqCourse('crew_leadership', 'Crew leadership and accountability', sortOrder: 60, description: 'Demonstrate roll call, assignments, accountability, conflict management, coaching, and safe supervision of a company.'),
      _reqCourse('training_delivery', 'Plan and deliver company training', sortOrder: 70, description: 'Develop, deliver, document, and evaluate a company-level training session or drill.'),
      _reqCourse('reports_documentation', 'Reports, documentation, and policy application', sortOrder: 80, description: 'Complete incident/training reports, apply department policies, and document personnel or operational issues appropriately.'),
      _reqCourse('preplan_inspection', 'Preplans, inspections, and target hazards', sortOrder: 90, description: 'Participate in pre-incident planning, occupancy familiarization, target-hazard review, and applicable company-level inspection duties.'),
      _reqCourse('acting_time', 'Documented acting / ride-up time', sortOrder: 100, description: 'Log supervised company-level acting assignments and feedback.'),
      _reqCourse('acting_officer_eval', 'Acting Officer evaluation', sortOrder: 110, description: 'Complete a department-defined acting-officer or company-officer practical evaluation before independent acting assignment when required.'),
      _reqCourse('promo_prep_co', 'Company officer promotional prep', sortOrder: 120, description: 'Written, assessment center, tactical scenario, and interview preparation for company officer.'),
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
      _reqCourse('multi_company_command', 'Multi-company incident command', sortOrder: 30, description: 'Demonstrate command of multi-unit incidents including divisions/groups, tactical priorities, accountability, resource requests, and transfer/termination of command.'),
      _reqCourse('chief_command_sim', 'Battalion-level command simulations', sortOrder: 40, description: 'Complete evaluated command scenarios covering structure fire, Mayday, multi-alarm, hazmat, wildland, or other locally relevant incidents.'),
      _reqCourse('shift_management', 'Shift staffing and operational coverage', sortOrder: 50, description: 'Demonstrate operational coverage decisions, callback/resource requests, move-ups, and continuity of service without turning Responder Roadmap into a scheduling system.'),
      _reqCourse('personnel_supervision', 'Personnel supervision and performance management', sortOrder: 60, description: 'Demonstrate coaching, documentation, conflict resolution, policy application, and escalation of personnel issues.'),
      _reqCourse('after_action', 'After-action review and improvement planning', sortOrder: 70, description: 'Lead or document an after-action review, identify lessons learned, assign follow-up actions, and close the loop on training needs.'),
      _reqCourse('multi_company', 'Documented shift / battalion leadership experience', sortOrder: 80, description: 'Log supervised battalion-level or multi-company leadership assignments and feedback.'),
      _reqCourse('promo_prep_bc', 'Battalion chief promotional prep', sortOrder: 90, description: 'Assessment, command scenarios, written exercise, and interview preparation.'),
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
      _reqCourse('exec_dev', 'Executive / senior officer development', sortOrder: 20, description: 'Leadership, labor, budget, strategic planning, public administration, or equivalent senior-officer development.'),
      _reqCourse('program_ownership', 'Major program or division ownership', sortOrder: 30, description: 'Documented ownership of training, operations, EMS, prevention, logistics, or another major department program.'),
      _reqCourse('budget_intro', 'Budget development and fiscal management', sortOrder: 40, description: 'Participate in budget development, purchasing, capital planning, grant, or fiscal-control work appropriate to the role.'),
      _reqCourse('policy_project', 'Policy or strategic improvement project', sortOrder: 50, description: 'Lead a policy revision, strategic initiative, accreditation/ISO project, risk-reduction effort, or other measurable department improvement.'),
      _reqCourse('interagency_leadership', 'Interagency and community leadership', sortOrder: 60, description: 'Represent the department in mutual-aid, city, county, regional, labor, community, or partner-agency work.'),
      _reqCourse('promo_prep_ac', 'Senior chief promotional prep', sortOrder: 70, description: 'Executive interview, strategic scenarios, written exercise, and portfolio preparation.'),
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
      _reqCourse('citywide_ops', 'Department-wide operations leadership', sortOrder: 20, description: 'Evidence of department-level operational decision-making, continuity planning, major incident support, and resource prioritization.'),
      _reqCourse('labor_budget', 'Labor, budget, and policy leadership', sortOrder: 30, description: 'Documented involvement in labor relations, budget development, policy approval, purchasing, discipline, or city/authority processes.'),
      _reqCourse('executive_staff', 'Executive staff leadership', sortOrder: 40, description: 'Lead cross-division staff work, executive briefings, strategic follow-through, and coordination among major department functions.'),
      _reqCourse('succession_project', 'Succession and organizational-development project', sortOrder: 50, description: 'Develop or lead a succession, leadership-development, workforce, training, or organizational-improvement initiative.'),
      _reqCourse('governance_exposure', 'Governance and elected-official exposure', sortOrder: 60, description: 'Participate in board, council, district, city-management, public-meeting, or equivalent governance processes where applicable.'),
      _reqCourse('promo_prep_dc', 'Deputy chief / executive prep', sortOrder: 70, description: 'Executive assessment, written exercise, portfolio, and interview preparation.'),
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
      _reqCourse('strategic_plan', 'Strategic planning and community risk leadership', sortOrder: 20, description: 'Lead or materially contribute to strategic planning, community risk reduction, standards of cover, or an equivalent executive planning process.'),
      _reqCourse('external_relations', 'Board, city, and community leadership', sortOrder: 30, description: 'Document work with elected officials, governing boards, city/county leadership, mutual-aid partners, labor, media, and community stakeholders.'),
      _reqCourse('executive_budget', 'Executive budget and capital planning', sortOrder: 40, description: 'Demonstrate executive-level understanding of operating budgets, capital plans, grants, fleet/facility needs, and long-term financial tradeoffs.'),
      _reqCourse('labor_culture', 'Labor relations and organizational culture', sortOrder: 50, description: 'Demonstrate constructive labor/management relationships, culture leadership, accountability, succession planning, and workforce development.'),
      _reqCourse('risk_governance', 'Enterprise risk, legal, and governance awareness', sortOrder: 60, description: 'Demonstrate working knowledge of executive risk, legal counsel relationships, policy governance, emergency management, and public accountability.'),
      _reqCourse('chief_portfolio', 'Fire Chief executive portfolio', sortOrder: 70, description: 'Assemble documented examples of strategic results, financial stewardship, labor/community relationships, operational leadership, and organizational improvement.'),
      _reqCourse('chief_promo_prep', 'Fire chief selection prep', sortOrder: 80, description: 'Executive interview, presentation, portfolio, and assessment preparation for fire chief processes.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const [],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),

  // ── Fire specialty path: Wildland Firefighter ───────────────────────────
  CareerGoal(
    id: 'wildland_fft2',
    title: 'Wildland Firefighter (FFT2)',
    category: 'Fire Specialty',
    description: 'Build the nationally recognized entry-level wildland fire foundation for Firefighter Type 2 (Crewmember), then complete your agency’s local qualification and certification process.',
    subtitle: 'NWCG foundation + agency qualification',
    typicalPrerequisiteRoles: const ['Recruit / Probationary', 'Firefighter', 'Wildland Firefighter'],
    requirements: <Requirement>[
      _reqCourse(
        'fft2_agency_orientation',
        'Wildland program and agency orientation',
        sortOrder: 10,
        description: 'Review your agency’s wildland program, PPE, deployment expectations, communications, medical plan, accountability, driving/transport practices, and local qualification process.',
      ),
      _reqCourse(
        'fft2_ics100',
        'ICS-100: Introduction to ICS',
        sortOrder: 20,
        description: 'Complete ICS-100 as required for NWCG Firefighter Type 2.',
      ),
      _reqCourse(
        'fft2_is700',
        'IS-700: NIMS, An Introduction',
        sortOrder: 30,
        description: 'Complete IS-700/NIMS introductory training as required for NWCG Firefighter Type 2.',
      ),
      _reqCourse(
        'fft2_l180',
        'L-180: Human Factors in the Wildland Fire Service',
        sortOrder: 40,
        description: 'Complete L-180 and apply human-performance, communication, leadership, and situational-awareness concepts to wildland operations.',
      ),
      _reqCourse(
        'fft2_s190',
        'S-190: Introduction to Wildland Fire Behavior',
        sortOrder: 50,
        description: 'Complete S-190 and demonstrate foundational recognition of fuels, weather, topography, fire behavior, and changing fire conditions.',
      ),
      _reqCourse(
        'fft2_s130',
        'S-130: Firefighter Training',
        sortOrder: 60,
        description: 'Complete S-130, including the required practical/incident exercise. S-190 is a prerequisite for the current NWCG S-130 course.',
      ),
      _reqCourse(
        'fft2_lces',
        'LCES and Standard Firefighting Orders',
        sortOrder: 70,
        description: 'Demonstrate Lookouts, Communications, Escape Routes, Safety Zones, the Standard Firefighting Orders, Watch Out Situations, and when to disengage.',
      ),
      _reqCourse(
        'fft2_fire_shelter',
        'Fire shelter and entrapment procedures',
        sortOrder: 80,
        description: 'Demonstrate inspection, carrying, deployment-site selection, shelter deployment, entrapment actions, and post-deployment considerations according to current agency training.',
      ),
      _reqCourse(
        'fft2_hand_tools',
        'Wildland hand tools and fireline construction',
        sortOrder: 90,
        description: 'Demonstrate safe tool use, spacing, scraping/cutting techniques, fireline construction to standard, and coordinated crew work.',
      ),
      _reqCourse(
        'fft2_progressive_hose',
        'Wildland hose, pumps, and water-use fundamentals',
        sortOrder: 100,
        description: 'Demonstrate the agency’s basic progressive hose lay, portable-pump, nozzle, and water-use procedures when applicable to the assigned resource.',
      ),
      _reqCourse(
        'fft2_mopup_patrol',
        'Mop-up, patrol, and cold-trailing fundamentals',
        sortOrder: 110,
        description: 'Demonstrate safe mop-up, patrol, cold trailing, hotspot identification, extinguishment, and communication of changing conditions.',
      ),
      _reqCourse(
        'fft2_radio',
        'Wildland radio communications',
        sortOrder: 120,
        description: 'Demonstrate radio programming/use appropriate to the agency, clear tactical communications, check-in, emergency traffic, and location reporting.',
      ),
      _reqCourse(
        'fft2_fitness',
        'Arduous physical-fitness qualification',
        sortOrder: 130,
        description: 'Meet the agency-approved measurable fitness standard for an NWCG position with an Arduous physical-fitness level. The evaluating agency determines the accepted test method.',
      ),
      _reqCourse(
        'fft2_field_eval',
        'Wildland field skills evaluation',
        sortOrder: 140,
        description: 'Complete an agency field evaluation covering PPE, fireline safety, tools, communications, fire behavior recognition, line construction, shelter use, and crew operations.',
      ),
      _reqCourse(
        'fft2_agency_certification',
        'Agency qualification / certification review',
        sortOrder: 150,
        description: 'Have the home unit or agency review the completed training and local requirements and determine whether you are qualified for deployment as FFT2 or the agency’s local equivalent. Responder Roadmap records progress but does not grant the qualification.',
      ),
      _reqCourse(
        'fft2_rt130',
        'RT-130 annual fireline safety refresher',
        sortOrder: 160,
        description: 'Complete RT-130 when required to maintain currency. NWCG notes that RT-130 is not required during the first year as FFT2 but is required in subsequent years.',
      ),
    ],
    recommendedExperience: <Requirement>[
      _reqCourse(
        'fft2_supervised_experience',
        'Supervised wildland field experience',
        sortOrder: 170,
        description: 'Participate in supervised wildland drills, prescribed fire, fuels work, or initial-attack operations when authorized by your agency.',
      ),
      _reqCourse(
        'fft2_next_qualification',
        'Plan the next wildland qualification',
        sortOrder: 180,
        description: 'After FFT2, identify whether FFT1 or an apparatus/single-resource qualification matches your agency role and development plan.',
      ),
    ],
    resourceIds: const ['nwcg_fft2', 'state_fire_authority'],
    nextRoles: const ['Firefighter Type 1 (FFT1)', 'Engine Boss (ENGB)'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),

  // ── EMS career ladder ───────────────────────────────────────────────────
  CareerGoal(
    id: 'ems_explorer',
    title: 'EMS Explorer / Student',
    category: 'EMS',
    description: 'Explore EMS careers and build readiness for EMT school.',
    subtitle: 'Curiosity → committed student',
    typicalPrerequisiteRoles: const [],
    requirements: <Requirement>[
      _reqCourse('ems_explore_ride', 'Observe or ride-along exposure', sortOrder: 10, description: 'Document observation time with an EMS agency when available.'),
      _reqCourse('ems_cpr_first_aid', 'CPR / First Aid readiness', sortOrder: 20, description: 'Complete current CPR/BLS (and first aid if required by your program).'),
      _reqCourse('ems_school_research', 'Research EMT programs', sortOrder: 30, description: 'Compare accredited EMT programs, schedules, and prerequisites.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['EMT Student'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_emt_student',
    title: 'EMT Student',
    category: 'EMS',
    description: 'Complete EMT education and clinical/field requirements.',
    subtitle: 'In EMT school',
    typicalPrerequisiteRoles: const ['EMS Explorer / Student'],
    requirements: <Requirement>[
      _reqCourse('emt_course', 'Complete EMT course', sortOrder: 10, description: 'Finish didactic and skills lab requirements for your EMT program.'),
      _reqCourse('emt_clinical', 'Clinical / field internship hours', sortOrder: 20, description: 'Log required hospital and ambulance internship hours.'),
      _reqCourse('emt_cognitive_exam', 'NREMT / state cognitive exam prep', sortOrder: 30, description: 'Prepare for and schedule the written exam used in your jurisdiction.'),
      _reqCourse('emt_psychomotor', 'Psychomotor / skills verification', sortOrder: 40, description: 'Complete skills testing required by your program or state.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['EMT'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_emt',
    title: 'EMT',
    category: 'EMS',
    description: 'Establish a solid EMT practice foundation and renewal discipline.',
    subtitle: 'Licensed / certified EMT',
    typicalPrerequisiteRoles: const ['EMT Student'],
    requirements: <Requirement>[
      _reqCert('emt_cred', 'EMT', defId: 'emt', sortOrder: 10, stateDependent: true),
      _reqCourse('emt_agency_onboard', 'Agency onboarding / protocols', sortOrder: 20, description: 'Complete orientation, protocols, and ride-time expectations for your agency.'),
      _reqCourse('emt_ce_plan', 'CE / renewal plan', sortOrder: 30, description: 'Track continuing education toward your next renewal cycle.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['Advanced EMT', 'Paramedic', 'EMS Instructor'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_aemt',
    title: 'Advanced EMT',
    category: 'EMS',
    description: 'Advance clinical capability beyond EMT while building toward paramedic or specialty work.',
    subtitle: 'AEMT pathway',
    typicalPrerequisiteRoles: const ['EMT'],
    requirements: <Requirement>[
      _reqCert('aemt_cred', 'AEMT', defId: 'aemt', sortOrder: 10, stateDependent: true),
      _reqCourse('aemt_protocol', 'AEMT protocol competency', sortOrder: 20, description: 'Document protocol review and skills sign-off for advanced interventions authorized in your system.'),
      _reqCourse('aemt_ce', 'AEMT CE / skills maintenance', sortOrder: 30, description: 'Maintain CE and skills verification for AEMT renewal.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['Paramedic'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_paramedic',
    title: 'Paramedic',
    category: 'EMS',
    description: 'Complete paramedic education and enter practice as a paramedic.',
    subtitle: 'Paramedic credential',
    typicalPrerequisiteRoles: const ['EMT', 'Advanced EMT'],
    requirements: <Requirement>[
      _reqCert('paramedic_cred', 'Paramedic', defId: 'paramedic', sortOrder: 10, stateDependent: true),
      _reqCourse('medic_program', 'Paramedic program completion', sortOrder: 20, description: 'Finish accredited paramedic coursework, clinicals, and field internship.'),
      _reqCourse('medic_exam', 'NREMT / state paramedic exam', sortOrder: 30, description: 'Pass the cognitive and skills requirements used in your jurisdiction.'),
      _reqCourse('medic_onboard', 'Agency paramedic onboarding', sortOrder: 40, description: 'Complete protocol, skills, and clearance steps for independent paramedic practice.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const [
      'Experienced Paramedic',
      'FTO / Preceptor',
      'EMS Supervisor',
      'Critical Care / Specialty EMS',
    ],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_experienced_paramedic',
    title: 'Experienced Paramedic',
    category: 'EMS',
    description: 'Build depth: complex calls, mentoring readiness, and specialty interest.',
    subtitle: 'Seasoned clinician',
    typicalPrerequisiteRoles: const ['Paramedic'],
    requirements: <Requirement>[
      _reqCourse('medic_complex_calls', 'Document complex / high-acuity experience', sortOrder: 10, description: 'Log challenging medical, trauma, and multi-patient incidents with reflection.'),
      _reqCourse('medic_ce_depth', 'Advanced CE / specialty education', sortOrder: 20, description: 'Complete advanced CE toward critical care, education, or leadership interests.'),
      _reqCourse('medic_peer_support', 'Peer coaching or mentoring hours', sortOrder: 30, description: 'Support newer clinicians through informal coaching or shift mentoring.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['FTO / Preceptor', 'EMS Instructor', 'EMS Supervisor'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_fto',
    title: 'FTO / Preceptor',
    category: 'EMS',
    description: 'Train and evaluate new EMS clinicians in the field.',
    subtitle: 'Field training officer',
    typicalPrerequisiteRoles: const ['Paramedic', 'Experienced Paramedic'],
    requirements: <Requirement>[
      _reqCourse('fto_course', 'FTO / preceptor course', sortOrder: 10, description: 'Complete your agency or state field-training officer / preceptor program.'),
      _reqCourse('fto_evals', 'Document trainee evaluations', sortOrder: 20, description: 'Complete structured evaluations and coaching notes for assigned trainees.'),
      _reqCourse('fto_feedback', 'Receive FTO program feedback', sortOrder: 30, description: 'Review program feedback and refine coaching approach.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['EMS Instructor', 'EMS Supervisor'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_instructor',
    title: 'EMS Instructor',
    category: 'EMS',
    description: 'Teach EMS courses and contribute to workforce development.',
    subtitle: 'EMS education track',
    typicalPrerequisiteRoles: const ['EMT', 'Paramedic', 'FTO / Preceptor'],
    requirements: <Requirement>[
      _reqCourse('ems_instructor_cred', 'EMS instructor credential / approval', sortOrder: 10, description: 'Meet state or program requirements to instruct EMS courses.'),
      _reqCourse('ems_teach_hours', 'Documented teaching hours', sortOrder: 20, description: 'Log classroom, skills-lab, or clinical instruction hours.'),
      _reqCourse('ems_curriculum', 'Course / skills-lab preparation', sortOrder: 30, description: 'Prepare lesson plans, skills sheets, and evaluations for a course you support.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['EMS Supervisor', 'EMS leadership'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_supervisor',
    title: 'EMS Supervisor',
    category: 'EMS',
    description: 'Shift or program supervision: people, quality, and daily operations.',
    subtitle: 'Front-line EMS leadership',
    typicalPrerequisiteRoles: const ['Paramedic', 'FTO / Preceptor', 'Experienced Paramedic'],
    requirements: <Requirement>[
      _reqCourse('ems_sup_leadership', 'Supervisory / leadership course', sortOrder: 10, description: 'Complete leadership, ICS, or supervisor coursework expected by your agency.'),
      _reqCourse('ems_sup_qa', 'QA / QI participation', sortOrder: 20, description: 'Document involvement in quality assurance or improvement reviews.'),
      _reqCourse('ems_sup_acting', 'Acting supervisor / charge experience', sortOrder: 30, description: 'Log supervised acting-supervisor or charge assignments.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['EMS Captain / Lieutenant', 'EMS Chief / Director'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_captain',
    title: 'EMS Captain / Lieutenant',
    category: 'EMS',
    description: 'Company- or shift-level EMS command and crew leadership.',
    subtitle: 'Company / shift officer',
    typicalPrerequisiteRoles: const ['EMS Supervisor', 'Paramedic'],
    requirements: <Requirement>[
      _reqCourse('ems_co_ops', 'Shift / company operations ownership', sortOrder: 10, description: 'Document ownership of staffing, readiness, and operational decisions for a crew or shift.'),
      _reqCourse('ems_co_training', 'Crew training coordination', sortOrder: 20, description: 'Plan and deliver recurring crew training or drills.'),
      _reqCourse('ems_co_promo', 'Officer promotional prep', sortOrder: 30, description: 'Prepare for written, assessment, or interview processes used for EMS officer roles.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const ['EMS Chief / Director'],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
  CareerGoal(
    id: 'ems_chief',
    title: 'EMS Chief / Director',
    category: 'EMS',
    description: 'Executive EMS leadership: strategy, systems, and community accountability.',
    subtitle: 'EMS system executive',
    typicalPrerequisiteRoles: const ['EMS Captain', 'EMS Supervisor', 'EMS Lieutenant'],
    requirements: <Requirement>[
      _reqCourse('ems_exec_strategy', 'Strategic / system planning', sortOrder: 10, description: 'Evidence of strategic planning, system design, or major program ownership.'),
      _reqCourse('ems_exec_budget', 'Budget / policy / labor exposure', sortOrder: 20, description: 'Documented involvement in budget, policy, labor, or board processes.'),
      _reqCourse('ems_exec_external', 'External / community leadership', sortOrder: 30, description: 'Work with hospitals, medical directors, elected officials, or regional partners.'),
      _reqCourse('ems_exec_prep', 'Chief / director selection prep', sortOrder: 40, description: 'Executive interview and portfolio preparation for EMS chief or director roles.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
    nextRoles: const [],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),

  // Specialty branches stay off the cumulative EMS ladder so they can expand
  // later (Community Paramedicine, Tactical, Flight, Education, Leadership)
  // without rewriting Personal navigation.
  CareerGoal(
    id: 'ems_specialty_critical_care',
    title: 'Critical Care / Specialty EMS',
    category: 'EMS Specialty',
    description: 'Prepare for critical care, CCT, or other specialty paramedic practice.',
    subtitle: 'Specialty branch · extensible',
    typicalPrerequisiteRoles: const ['Paramedic', 'Experienced Paramedic'],
    requirements: <Requirement>[
      _reqCert('paramedic_cc', 'Paramedic', defId: 'paramedic', sortOrder: 10, stateDependent: true),
      _reqCourse('cc_course', 'Critical care / specialty course', sortOrder: 20, description: 'Complete a critical care, CCT, or agency specialty program recognized in your system.'),
      _reqCourse('cc_clinical', 'Specialty clinical / transport experience', sortOrder: 30, description: 'Document required specialty clinical or transport hours.'),
      _reqCourse('cc_protocol', 'Specialty protocol competency', sortOrder: 40, description: 'Complete protocol and equipment competencies for the specialty assignment.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_ems_authority'],
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

Requirement _reqDepartmentGate(
  String id,
  String name, {
  required int sortOrder,
  required String description,
}) {
  return Requirement(
    id: id,
    name: name,
    category: 'Department',
    priority: RequirementPriority.department,
    description: description,
    type: RequirementType.trainingCourse,
    requirementSource: RequirementSource.departmentRequirement,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: true,
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
    timelineCategory: TimelineCategory.departmentRequirement,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: _seedNow,
    updatedAt: _seedNow,
  );
}

Requirement _reqPromotionStep(
  String id,
  String name, {
  required int sortOrder,
  required RequirementType type,
  required String description,
}) {
  return Requirement(
    id: id,
    name: name,
    category: 'Promotion Process',
    priority: RequirementPriority.department,
    description: description,
    type: type,
    requirementSource: RequirementSource.departmentRequirement,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: true,
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
    canRunConcurrent: false,
    timelineCategory: TimelineCategory.promotionalPreparation,
    suggestedStartDate: null,
    suggestedCompletionDate: null,
    createdAt: _seedNow,
    updatedAt: _seedNow,
  );
}

Requirement _reqEvidenceMilestone(
  String id,
  String name, {
  required int sortOrder,
  required String description,
}) {
  return Requirement(
    id: id,
    name: name,
    category: 'Leadership Evidence',
    priority: RequirementPriority.development,
    description: description,
    type: RequirementType.numericProgress,
    requirementSource: RequirementSource.recommended,
    defaultRequired: true,
    stateDependent: false,
    departmentDependent: false,
    completed: false,
    progressCurrent: 0,
    progressRequired: 1,
    progressUnit: 'documented example',
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
    timelineCategory: TimelineCategory.development,
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
