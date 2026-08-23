import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/certification_definition.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/resource.dart';

/// Stable catalog facade used across the app.
///
/// Historically this project exposed a large monolithic `FireOpsCatalog` from
/// `lib/services/catalog.dart`. During refactors, callers across controllers,
/// pages, and tests still rely on this API.
///
/// This file intentionally keeps that API stable.
///
/// Notes:
/// - Catalog entries are local-only (no backend).
/// - IDs are treated as stable keys and should not be changed lightly.
/// - Keep these methods pure and side-effect-free.
class FireOpsCatalog {
  FireOpsCatalog._();

  /// Used when the user does not want to select a specific US state.
  static const String otherStateCode = 'OTHER';

  // ---------------------------------------------------------------------------
  // Roles / onboarding helpers
  // ---------------------------------------------------------------------------

  static const List<String> commonRoles = <String>[
    'Firefighter',
    'Firefighter (Probationary)',
    'Driver/Operator',
    'Engineer',
    'Company Officer',
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

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  static final List<UsStateOption> usStateOptions = <UsStateOption>[
    ..._usStates,
    const UsStateOption(code: otherStateCode, name: 'Other / Outside US'),
  ];

  static String? stateNameForCode(String? code) {
    final c = code?.trim().toUpperCase();
    if (c == null || c.isEmpty) return null;
    return _stateNameByCode[c];
  }

  /// Returns a canonical state code (e.g. `CA`) from user-entered or legacy
  /// values.
  ///
  /// Supports:
  /// - Two-letter codes
  /// - Full state names
  /// - "Other" / unknown values
  static String? stateCodeFromLegacyValue(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;

    final upper = v.toUpperCase();
    if (upper == otherStateCode) return otherStateCode;

    // Two-letter code.
    if (upper.length == 2 && _stateNameByCode.containsKey(upper)) return upper;

    final normalized = upper.replaceAll(RegExp(r'[^A-Z]+'), ' ').trim();
    if (normalized.isEmpty) return null;
    if (normalized == 'OTHER' || normalized == 'OUTSIDE US') return otherStateCode;

    return _stateCodeByName[normalized];
  }

  static String stateCodeFromLegacyValueOrOther(String? raw) =>
      stateCodeFromLegacyValue(raw) ?? otherStateCode;

  // ---------------------------------------------------------------------------
  // Certifications
  // ---------------------------------------------------------------------------

  static List<CertificationDefinition> certificationDefinitions() =>
      _certifications;

  static Map<String, CertificationDefinition> certificationById() =>
      _certById;

  /// Normalizes user-entered certification text for matching.
  static String normalizeCertificationText(String value) {
    final v = value.toLowerCase().trim();
    if (v.isEmpty) return '';
    return v
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Attempts to match a free-form label (e.g. "FF1", "Firefighter I") to a
  /// stable [CertificationDefinition.id].
  static String? matchCertificationDefinitionId(String input) {
    final n = normalizeCertificationText(input);
    if (n.isEmpty) return null;
    return _certMatchIndex[n];
  }

  // ---------------------------------------------------------------------------
  // Resources / goals
  // ---------------------------------------------------------------------------

  static List<Resource> resources() => _resources;

  static List<CareerGoal> goals() => _goals;

  /// Sanity checks that can run at startup in debug/dev.
  ///
  /// Keep this fast and side-effect-free.
  static void validateCatalog() {
    assert(() {
      // Ensure unique certification IDs.
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

// -----------------------------------------------------------------------------
// Private catalog data (minimal baseline; expand as needed)
// -----------------------------------------------------------------------------

final DateTime _seedNow = DateTime(2026, 8, 23);

final List<CertificationDefinition> _certifications = <CertificationDefinition>[
  CertificationDefinition(
    id: 'firefighter_1',
    displayName: 'Firefighter I',
    shortName: 'FF1',
    category: CertificationCategory.firefighting,
    description: 'Entry-level structural firefighting certification (name varies by state/provider).',
    aliases: const ['Fire Fighter 1', 'Fire Fighter I', 'Firefighter 1'],
    prerequisiteCertificationIds: const [],
    recommendedPrerequisiteIds: const [],
    typicallyExpires: false,
    typicalRenewalYears: null,
    stateDependent: true,
    nationalCredential: false,
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    resourceIds: const [],
    searchKeywords: const ['ff1', 'firefighter i', 'firefighter 1'],
    renewalDescription: null,
    continuingEducationNotes: null,
    renewalResourceIds: const [],
  ),
  CertificationDefinition(
    id: 'firefighter_2',
    displayName: 'Firefighter II',
    shortName: 'FF2',
    category: CertificationCategory.firefighting,
    description: 'Advanced structural firefighting certification (name varies by state/provider).',
    aliases: const ['Fire Fighter 2', 'Fire Fighter II', 'Firefighter 2'],
    prerequisiteCertificationIds: const ['firefighter_1'],
    recommendedPrerequisiteIds: const [],
    typicallyExpires: false,
    typicalRenewalYears: null,
    stateDependent: true,
    nationalCredential: false,
    issuingOrganizations: const ['State fire authority / AHJ', 'IFSAC / Pro Board (where applicable)'],
    relatedCareerGoalIds: const ['ops_engineer', 'ops_officer'],
    resourceIds: const [],
    searchKeywords: const ['ff2', 'firefighter ii', 'firefighter 2'],
    renewalDescription: null,
    continuingEducationNotes: null,
    renewalResourceIds: const [],
  ),
  CertificationDefinition(
    id: 'driver_operator_pumper',
    displayName: 'Driver/Operator – Pumper',
    shortName: 'D/O Pumper',
    category: CertificationCategory.driverOperator,
    description: 'Driver/operator (engine/pumper) certification or qualification. Requirements vary by state and department.',
    aliases: const ['Driver Operator Pumper', 'Engineer Pumper', 'Pump Operator'],
    prerequisiteCertificationIds: const ['firefighter_1'],
    recommendedPrerequisiteIds: const [],
    typicallyExpires: false,
    typicalRenewalYears: null,
    stateDependent: true,
    nationalCredential: false,
    issuingOrganizations: const ['State fire authority / AHJ', 'Department'],
    relatedCareerGoalIds: const ['ops_engineer'],
    resourceIds: const [],
    searchKeywords: const ['driver operator', 'pumper', 'engineer', 'pump operator'],
    renewalDescription: null,
    continuingEducationNotes: null,
    renewalResourceIds: const [],
  ),
  CertificationDefinition(
    id: 'emt',
    displayName: 'EMT',
    shortName: null,
    category: CertificationCategory.ems,
    description: 'Emergency Medical Technician credential (state/NREMT depending on jurisdiction).',
    aliases: const ['Emergency Medical Technician', 'NREMT EMT'],
    prerequisiteCertificationIds: const [],
    recommendedPrerequisiteIds: const [],
    typicallyExpires: true,
    typicalRenewalYears: 2,
    stateDependent: true,
    nationalCredential: true,
    issuingOrganizations: const ['NREMT', 'State EMS office'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    resourceIds: const [],
    searchKeywords: const ['emt', 'nremt'],
    renewalDescription: 'Renewal rules vary. Track your CE and follow your state/NREMT policy.',
    continuingEducationNotes: 'Confirm current CE hour distribution and skills verification rules for your state and NREMT.',
    renewalResourceIds: const [],
  ),
  CertificationDefinition(
    id: 'aemt',
    displayName: 'AEMT',
    shortName: null,
    category: CertificationCategory.ems,
    description: 'Advanced EMT credential (state/NREMT depending on jurisdiction).',
    aliases: const ['Advanced EMT', 'NREMT AEMT'],
    prerequisiteCertificationIds: const ['emt'],
    recommendedPrerequisiteIds: const [],
    typicallyExpires: true,
    typicalRenewalYears: 2,
    stateDependent: true,
    nationalCredential: true,
    issuingOrganizations: const ['NREMT', 'State EMS office'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    resourceIds: const [],
    searchKeywords: const ['aemt', 'advanced emt'],
    renewalDescription: 'Renewal rules vary. Track your CE and follow your state/NREMT policy.',
    continuingEducationNotes: 'Confirm current CE hour distribution and skills verification rules for your state and NREMT.',
    renewalResourceIds: const [],
  ),
  CertificationDefinition(
    id: 'paramedic',
    displayName: 'Paramedic',
    shortName: null,
    category: CertificationCategory.ems,
    description: 'Paramedic credential (state/NREMT depending on jurisdiction).',
    aliases: const ['NREMT Paramedic'],
    prerequisiteCertificationIds: const ['emt'],
    recommendedPrerequisiteIds: const [],
    typicallyExpires: true,
    typicalRenewalYears: 2,
    stateDependent: true,
    nationalCredential: true,
    issuingOrganizations: const ['NREMT', 'State EMS office'],
    relatedCareerGoalIds: const ['ops_firefighter', 'ops_engineer'],
    resourceIds: const [],
    searchKeywords: const ['paramedic', 'medic'],
    renewalDescription: 'Renewal rules vary. Track your CE and follow your state/NREMT policy.',
    continuingEducationNotes: 'Confirm current CE hour distribution and skills verification rules for your state and NREMT.',
    renewalResourceIds: const [],
  ),
];

final Map<String, CertificationDefinition> _certById = {
  for (final d in _certifications) d.id: d,
};

final Map<String, String> _certMatchIndex = () {
  final out = <String, String>{};
  void add(String key, String id) {
    final n = FireOpsCatalog.normalizeCertificationText(key);
    if (n.isEmpty) return;
    out.putIfAbsent(n, () => id);
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

  // Extra common shorthands.
  add('ff i', 'firefighter_1');
  add('ff 1', 'firefighter_1');
  add('ff ii', 'firefighter_2');
  add('ff 2', 'firefighter_2');
  add('do pumper', 'driver_operator_pumper');
  add('driver operator', 'driver_operator_pumper');
  add('pump ops', 'driver_operator_pumper');
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
      _reqCert('haz_awareness', 'HazMat Awareness', sortOrder: 20, stateDependent: true, allowExpired: false),
      _reqCert('haz_ops', 'HazMat Operations', sortOrder: 30, stateDependent: true, allowExpired: false),
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

      // State-dependent guidance example: this is NOT a verified mandate, but we
      // want the UI to attach the correct state authority source.
      _reqCourse(
        'state_driver_policy',
        'State driver/operator policy check',
        sortOrder: 30,
        stateDependent: true,
        description: 'Confirm your state’s current driver/operator training and certification policy, then confirm your department SOPs.',
      ),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const ['Company Officer'],
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
