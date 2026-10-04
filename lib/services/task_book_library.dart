import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';

/// Built-in FireOps Preparation Tasks.
///
/// IMPORTANT: These are not official skill sheets.
class TaskBookLibrary {
  /// Returns a qualification task book (tasks grouped into sections) when
  /// FireOps has a starter set for the given requirement.
  ///
  /// For now we key off known certificationDefinitionIds + well-known titles.
  static List<TaskBookTaskDefinition> tasksForRequirement(Requirement r) {
    final defId = r.certificationDefinitionId;
    if (defId == 'driver_operator_pumper') {
      return _withCompanionResources(
        _driverOperatorPumper(),
        certificationId: 'driver_operator_pumper',
      );
    }
    final name = r.name.trim().toLowerCase();
    if (name.contains('driver operator') && name.contains('pumper')) {
      return _withCompanionResources(
        _driverOperatorPumper(),
        certificationId: 'driver_operator_pumper',
      );
    }
    return const <TaskBookTaskDefinition>[];
  }

  static bool hasTasksForRequirement(Requirement r) =>
      tasksForRequirement(r).isNotEmpty;

  /// Explicit testing gates shown at the end of certification-oriented task
  /// books. These are personal progress checkoffs only; the official testing
  /// authority determines whether the candidate actually passed.
  static List<TaskBookTaskDefinition> certificationCompletionGates(
    Requirement requirement,
  ) {
    if (requirement.type != RequirementType.certification) {
      return const <TaskBookTaskDefinition>[];
    }

    final hasDetailedProcess =
        requirement.certificationDefinitionId == 'firefighter_2' ||
        requirement.name.trim().toLowerCase() == 'firefighter ii' ||
        requirement.name.trim().toLowerCase() == 'firefighter 2';

    const passGates = <TaskBookTaskDefinition>[
      TaskBookTaskDefinition(
        id: 'cert_pass_jpr_practical',
        title: 'Pass JPR / practical evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Record completion only after the official practical/JPR evaluation has been passed through the applicable testing authority.',
        whatToKnow: [
          'The official evaluator packet, testing authority, and current passing criteria control the result.',
          'Responder Roadmap does not determine or grant a passing practical result.',
        ],
        performanceTasks: [
          'Complete the official practical/JPR evaluation.',
          'Confirm the testing authority recorded a passing result.',
          'Retain result documentation when available.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Marking practice or a mock evaluation as the official passing JPR result.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_pass_written_test',
        title: 'Pass written test',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Record completion only after the official written or knowledge examination has been passed through the applicable testing authority.',
        whatToKnow: [
          'Use the current candidate handbook or testing authority information for passing score, retest rules, and exam requirements.',
          'Responder Roadmap records the result but does not determine a passing score.',
        ],
        performanceTasks: [
          'Complete the official written/knowledge examination.',
          'Confirm the testing authority recorded a passing result.',
          'Retain result documentation when available.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Treating course completion or a practice exam as the official written-test result.',
        ],
        practiceTools: [],
        resources: [],
      ),
    ];

    if (hasDetailedProcess) return passGates;

    return const <TaskBookTaskDefinition>[
      TaskBookTaskDefinition(
        id: 'cert_confirm_official_requirements',
        title: 'Confirm official certification requirements',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Identify the exact authority, current candidate information, prerequisites, and required steps for this certification.',
        whatToKnow: [
          'Certification requirements can vary by state, department, academy, testing provider, and revision.',
        ],
        performanceTasks: [
          'Identify the certifying or recognizing authority.',
          'Save the current official certification page or candidate handbook.',
          'Confirm prerequisites, eligibility, and application rules.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Following a generic checklist without confirming the authority that applies to you.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_confirm_jpr_list',
        title: 'Confirm required JPRs / practical stations',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Use the current official skill/JPR packet to define exactly what practical performance must be mastered.',
        whatToKnow: [
          'Responder Roadmap does not invent official JPR criteria.',
        ],
        performanceTasks: [
          'Obtain the current official JPR or practical packet.',
          'Confirm the revision/effective date.',
          'Add individual JPR mastery items as custom Task Book tasks when separate checkboxes are useful.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Practicing from an outdated or unofficial skill sheet.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_confirm_reading',
        title: 'Confirm required reading and study material',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Identify the exact textbook edition, chapters, modules, standards, and candidate material required by the provider.',
        whatToKnow: [
          'Reading assignments differ between programs even when the certification title is the same.',
        ],
        performanceTasks: [
          'Confirm the required textbook/reference edition.',
          'Confirm assigned chapters or modules.',
          'Add major reading assignments as separate custom tasks when you want chapter-by-chapter checkoffs.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Using the wrong edition or assuming a study guide replaces assigned material.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_complete_required_training',
        title: 'Complete required course or training',
        section: 'TRAINING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the approved instruction required before testing or certification.',
        whatToKnow: [
          'Attendance, course hours, assignments, labs, and instructor sign-offs vary by provider.',
        ],
        performanceTasks: [
          'Enroll in the approved course or training pathway.',
          'Complete attendance, modules, assignments, and required practice.',
          'Save course completion documentation.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming training completion automatically issues the certification.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_master_practical_requirements',
        title: 'Master each required JPR / practical station',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Work through every official practical station until performance is consistent and ready for formal evaluation.',
        whatToKnow: [
          'Mastery here is preparation status; only the official testing authority determines a pass.',
        ],
        performanceTasks: [
          'Practice every official JPR/station with the current criteria.',
          'Use separate custom tasks for JPR 1, JPR 2, and additional stations when you want individual checkoffs.',
          'Repeat weak stations until performance is consistent.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Calling one successful practice attempt mastery.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_find_test_location',
        title: 'Find approved testing location or provider',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Identify where the required written and practical testing can be completed for the credential pathway that applies to you.',
        whatToKnow: [
          'Written and practical components may use different providers or locations.',
        ],
        performanceTasks: [
          'Find an approved written-test provider or site.',
          'Find an approved practical/JPR provider or site.',
          'Save the testing instructions and contact information.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Choosing a convenient testing site before confirming the result is accepted.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'cert_register_testing',
        title: 'Register for required testing',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the administrative steps needed to secure your written and practical testing dates.',
        whatToKnow: [
          'Check deadlines, fees, identification, prerequisite documentation, PPE/equipment, and retest rules.',
        ],
        performanceTasks: [
          'Register for the written/knowledge exam when required.',
          'Register or schedule the practical/JPR evaluation when required.',
          'Save confirmations and testing dates.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming course registration also registers you for certification testing.',
        ],
        practiceTools: [],
        resources: [],
      ),
      ...passGates,
      TaskBookTaskDefinition(
        id: 'cert_confirm_issuance',
        title: 'Confirm certification was issued',
        section: 'CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Finish the process by confirming the credential was formally issued or recorded by the applicable authority.',
        whatToKnow: [
          'Some authorities issue automatically after testing; others require an application, fee, affiliation, or department verification.',
        ],
        performanceTasks: [
          'Complete any post-test application or document submission.',
          'Confirm the credential appears in the official system or has been issued.',
          'Add the credential and expiration/Does Not Expire status to Responder Roadmap.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Stopping after passing the tests without verifying formal issuance.',
        ],
        practiceTools: [],
        resources: [],
      ),
    ];
  }

  static List<TaskBookTaskDefinition> _withCompanionResources(
    List<TaskBookTaskDefinition> tasks, {
    required String certificationId,
  }) {
    return tasks
        .map(
          (task) => TaskBookTaskDefinition(
            id: task.id,
            title: task.title,
            section: task.section,
            goalId: task.goalId,
            requirementId: task.requirementId,
            isCustom: task.isCustom,
            fireOpsObjective: task.fireOpsObjective,
            whatToKnow: task.whatToKnow,
            performanceTasks: task.performanceTasks,
            safetyPoints: task.safetyPoints,
            commonMistakes: task.commonMistakes,
            practiceTools: task.practiceTools,
            resources: [
              ...task.resources,
              TaskBookResourceLink(
                title: 'FireOpsSim: study, practice, and training help',
                url:
                    'https://fireopssim.com/taskbook-resources.html?cert=$certificationId&task=${task.id}&source=roadmap',
                type: TaskBookTaskResourceType.fireOpsGuide,
                issuingSource: 'FireOpsSim',
                notes:
                    'Free companion study material, practice tools, class finder, and official source links.',
                fileRef: null,
              ),
            ],
          ),
        )
        .toList(growable: false);
  }

  static List<TaskBookTaskDefinition> _driverOperatorPumper() {
    const fireOps = 'FireOps Preparation Tasks';
    return const [
      TaskBookTaskDefinition(
        id: 'do_pumper_pump_theory',
        title: 'Pump theory (overview)',
        section: 'KNOWLEDGE',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Build a working understanding of pump principles so you can diagnose problems under stress.',
        whatToKnow: [
          'Positive displacement vs centrifugal pumps (high-level)',
          'Net pump pressure basics (PDP / intake / discharge relationships)',
          'Priming purpose and limitations',
          'Cavitation warning signs and consequences',
        ],
        performanceTasks: [
          'Explain pump modes/controls used on your apparatus (instructor-led)',
          'Identify common gauges/indicators and what “normal” looks like',
        ],
        safetyPoints: [
          'Never rely on a single gauge—confirm water supply and line status.',
        ],
        commonMistakes: [
          'Chasing pressure without verifying intake supply',
          'Over-priming or priming with incorrect valves set',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Open FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Pump operations practice scenarios',
          ),
          TaskBookPracticeToolLink(
            title: 'Open FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'Friction loss and PDP quick math',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_apparatus_inspection',
        title: 'Daily apparatus inspection (driver check)',
        section: 'APPARATUS OPERATIONS',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Build a repeatable inspection routine that catches safety issues early.',
        whatToKnow: [
          'Your department’s inspection checklist / documentation process',
          'Critical pump controls, valves, interlocks, and indicators',
          'Tank level, foam system basics (if applicable)',
        ],
        performanceTasks: [
          'Perform the inspection using your department checklist',
          'Identify and report deficiencies per SOP',
        ],
        safetyPoints: [
          'Use wheel chocks / parking brake where required by SOP.',
          'Lockout/tagout procedures if needed.',
        ],
        commonMistakes: [
          'Rushing and skipping critical items (tires, fluids, pump panel)',
          'Failing to document small issues that become big failures',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_engage_pump',
        title: 'Engage pump (basic sequence)',
        section: 'APPARATUS OPERATIONS',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Safely transition from drive to pump mode and confirm readiness for water operations.',
        whatToKnow: [
          'Your apparatus-specific pump engage sequence and interlocks',
          'What indicators confirm pump engaged (RPM, pressure, lights)',
        ],
        performanceTasks: [
          'Follow the manufacturer + department sequence',
          'Confirm pump engaged and stable before opening intakes/discharges',
        ],
        safetyPoints: [
          'Confirm transmission in correct mode before engaging.',
          'Communicate clearly with crew before charging lines.',
        ],
        commonMistakes: [
          'Engaging with incorrect RPM or drivetrain state',
          'Opening discharges before confirming supply / valve positions',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Simulated pump panel decisions',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_hydrant_ops',
        title: 'Hydrant operations (supply from municipal source)',
        section: 'APPARATUS OPERATIONS',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Establish a reliable hydrant supply and manage intake pressure safely.',
        whatToKnow: [
          'Hydrant types (dry vs wet barrel) and basic operation',
          'Water hammer risks and opening/closing discipline',
          'Intake pressure monitoring and when to throttle back',
        ],
        performanceTasks: [
          'Connect to hydrant and establish supply per SOP',
          'Monitor intake/discharge pressures and adjust for demand changes',
        ],
        safetyPoints: [
          'Avoid standing over outlets / caps during pressurization.',
          'Watch hose movement and communicate with hydrant firefighter.',
        ],
        commonMistakes: [
          'Opening hydrant too quickly',
          'Failing to anticipate demand changes (multiple lines opening)',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Hydrant Flow Calculator',
            route: '/resources?tool=hydrant_flow',
            subtitle: 'Estimate available flow from hydrant data',
          ),
          TaskBookPracticeToolLink(
            title: 'Open FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'PDP + friction loss quick calculations',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_drafting',
        title: 'Drafting from a static water source',
        section: 'APPARATUS OPERATIONS',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Demonstrate the ability to establish a reliable water supply from a static source using fire apparatus.',
        whatToKnow: [
          'How drafting works (atmospheric pressure / lift limitations)',
          'Priming purpose and common failure modes',
          'Suction hose, gaskets, and air leak troubleshooting',
          'Strainer placement and avoiding vortexing',
          'Cavitation warning signs',
        ],
        performanceTasks: [
          'Position apparatus safely for drafting operations.',
          'Select appropriate suction equipment for the source.',
          'Assemble suction hose and confirm gasket integrity.',
          'Position the strainer correctly and control for debris/vortex.',
          'Engage the pump and set valves/intake appropriately.',
          'Prime the pump and confirm stable intake conditions.',
          'Transition to discharge operations and maintain supply.',
          'Monitor for loss of prime/cavitation and correct early.',
        ],
        safetyPoints: [
          'Control traffic / scene hazards near static sources.',
          'Avoid slip/trip hazards around water edge and hose.',
          'Use PPE and follow department SOP for water-side operations.',
        ],
        commonMistakes: [
          'Air leaks at gaskets / caps causing loss of prime',
          'Strainer too shallow leading to vortexing',
          'Over-priming or failing to bleed air appropriately',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Drafting scenarios and troubleshooting',
          ),
          TaskBookPracticeToolLink(
            title: 'Open FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'Friction loss + PDP for draft operations',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_friction_loss',
        title: 'Friction loss + pump discharge pressure (PDP)',
        section: 'KNOWLEDGE',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Build repeatable friction loss habits to support safe and effective line operations.',
        whatToKnow: [
          'Friction loss factors (flow, hose diameter, length)',
          'Nozzle pressure concepts (per your nozzles/SOP)',
          'Appliance loss basics (gated wyes, master stream devices)',
        ],
        performanceTasks: [
          'Compute a target PDP for 1¾" and 2½" lines (training context)',
          'Adjust PDP for multiple lines while maintaining intake safety',
        ],
        safetyPoints: [
          'Avoid over-pressurizing hose/nozzles beyond ratings/SOP.',
        ],
        commonMistakes: [
          'Forgetting to account for elevation or appliances when applicable',
          'Chasing nozzle reaction complaints without checking flow',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Open FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'Friction loss + PDP calculator',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_multiple_attack_lines',
        title: 'Supply multiple attack lines',
        section: 'PERFORMANCE',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Maintain stable pressures while multiple discharges are operating and changing.',
        whatToKnow: [
          'Discharge management (gating, pressure relief/governor)',
          'Communications with crews opening/closing lines',
        ],
        performanceTasks: [
          'Establish a baseline PDP, then manage changes as lines open/close',
          'Demonstrate controlled adjustments without wild pressure swings',
        ],
        safetyPoints: [
          'Avoid sudden pressure changes (water hammer / hose movement).',
        ],
        commonMistakes: [
          'Late recognition of demand changes',
          'Over-correcting throttle and oscillating pressure',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Multi-line pump ops scenarios',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_master_streams',
        title: 'Master stream operations (basic support)',
        section: 'PERFORMANCE',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Support master stream devices safely with appropriate pressures/flows.',
        whatToKnow: [
          'High flow impacts on intake supply and relay needs',
          'Appliance loss considerations (training context)',
        ],
        performanceTasks: [
          'Set up and supply master stream per SOP',
          'Recognize when additional supply/relay is required',
        ],
        safetyPoints: [
          'Confirm device anchoring and collapse zones (incident safety).',
        ],
        commonMistakes: ['Underestimating required flow/supply needs'],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Open FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'High flow friction loss quick checks',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_relay_pumping',
        title: 'Relay pumping (overview)',
        section: 'PERFORMANCE',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Understand relay basics and the critical communication needed to avoid supply failures.',
        whatToKnow: [
          'Basic relay concepts (intake/discharge, spacing, communications)',
          'Pressure targets and avoiding over-pressurization',
        ],
        performanceTasks: [
          'Describe relay roles (source, intermediate, attack pumper)',
          'Demonstrate stable discharge pressure in a simple relay scenario',
        ],
        safetyPoints: ['Monitor line ratings and use relief devices per SOP.'],
        commonMistakes: ['Poor communication causing pressure spikes/drops'],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Relay pumping practice',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_pumper_troubleshooting',
        title: 'Troubleshoot pressure / supply problems',
        section: 'PERFORMANCE',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            '$fireOps: Diagnose common pump and supply issues quickly and safely.',
        whatToKnow: [
          'Common causes: air leaks, intake restriction, cavitation, closed valves',
          'How to confirm if the issue is supply vs discharge vs pump mode',
        ],
        performanceTasks: [
          'Identify likely cause from symptoms (training scenarios)',
          'Apply a safe correction plan and confirm stabilization',
        ],
        safetyPoints: [
          'Prioritize crew safety and water supply stability over “perfect” pressures.',
        ],
        commonMistakes: [
          'Making multiple changes at once and losing track of cause/effect',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Troubleshooting scenarios',
          ),
        ],
        resources: [],
      ),
    ];
  }
}
