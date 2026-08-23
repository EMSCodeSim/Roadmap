#!/usr/bin/env python3
"""Restore full operations career ladder through Fire Chief in catalog.dart."""

from pathlib import Path

CATALOG = Path("lib/services/catalog/catalog.dart")

NEW_COMMON_ROLES = """  static const List<String> commonRoles = <String>[
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
  ];"""

# Full goals block — paste carefully into the file by replacing the existing _goals list.
NEW_GOALS_BLOCK = r'''final List<CareerGoal> _goals = <CareerGoal>[
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
      _reqCourse('ics300', 'ICS 300', sortOrder: 30, stateDependent: false, description: 'Intermediate ICS for expanding incidents and supervisory roles.'),
      _reqCourse('acting_time', 'Documented acting / ride-up time', sortOrder: 40, stateDependent: false, description: 'Log supervised company-level acting assignments and feedback.'),
      _reqCourse('promo_prep_co', 'Company officer promotional prep', sortOrder: 50, stateDependent: false, description: 'Written, assessment center, and interview preparation for company officer.'),
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
      _reqCourse('ics400', 'ICS 400', sortOrder: 20, stateDependent: false, description: 'Advanced ICS for complex incident management and area command concepts.'),
      _reqCourse('multi_company', 'Multi-company / shift command experience', sortOrder: 30, stateDependent: false, description: 'Documented command of multi-unit responses and shift-level leadership.'),
      _reqCourse('promo_prep_bc', 'Battalion chief promotional prep', sortOrder: 40, stateDependent: false, description: 'Assessment, command scenarios, and interview preparation.'),
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
      _reqCourse('exec_dev', 'Executive / senior officer development', sortOrder: 20, stateDependent: false, description: 'Leadership, labor, budget, and strategic planning coursework or program.'),
      _reqCourse('program_ownership', 'Major program or division ownership', sortOrder: 30, stateDependent: false, description: 'Documented ownership of training, ops, EMS, prevention, or similar major program.'),
      _reqCourse('promo_prep_ac', 'Senior chief promotional prep', sortOrder: 40, stateDependent: false, description: 'Executive interview, strategic scenarios, and portfolio preparation.'),
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
      _reqCourse('citywide_ops', 'Citywide / department operations leadership', sortOrder: 20, stateDependent: false, description: 'Evidence of department-level operational decision-making and coverage planning.'),
      _reqCourse('labor_budget', 'Labor, budget, or policy exposure', sortOrder: 30, stateDependent: false, description: 'Documented involvement in budget, labor relations, policy, or city processes.'),
      _reqCourse('promo_prep_dc', 'Deputy chief / executive prep', sortOrder: 40, stateDependent: false, description: 'Executive assessment and interview preparation.'),
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
      _reqCourse('strategic_plan', 'Strategic plan / CRR leadership', sortOrder: 20, stateDependent: false, description: 'Evidence of strategic planning, community risk reduction, or equivalent executive work.'),
      _reqCourse('external_relations', 'City / board / community leadership', sortOrder: 30, stateDependent: false, description: 'Documented work with elected officials, boards, mutual aid, or community partners.'),
      _reqCourse('chief_promo_prep', 'Fire chief selection prep', sortOrder: 40, stateDependent: false, description: 'Executive interview, portfolio, and assessment preparation for fire chief processes.'),
    ],
    recommendedExperience: const [],
    resourceIds: const ['state_fire_authority'],
    nextRoles: const [],
    createdAt: _seedNow,
    updatedAt: _seedNow,
  ),
];'''

def main():
    text = CATALOG.read_text()

    # 1) commonRoles
    import re
    text2, n = re.subn(
        r"static const List<String> commonRoles = <String>\[[\s\S]*?\];",
        NEW_COMMON_ROLES,
        text,
        count=1,
    )
    if n != 1:
        raise SystemExit("Could not uniquely replace commonRoles")

    # 2) _goals list
    text3, n2 = re.subn(
        r"final List<CareerGoal> _goals = <CareerGoal>\[[\s\S]*?\];",
        NEW_GOALS_BLOCK,
        text2,
        count=1,
    )
    if n2 != 1:
        raise SystemExit("Could not uniquely replace _goals")

    CATALOG.write_text(text3)
    print("Updated commonRoles and restored full _goals ladder through Fire Chief.")
    print("NOTE: You still need to add fire_officer_1..4 and fire_instructor_1 CertificationDefinitions if missing,")
    print("and ensure _reqCert / _reqCourse helpers accept the arguments used above.")

if __name__ == "__main__":
    main()
