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
    if (defId == 'driver_operator_pumper') return _driverOperatorPumper();
    final name = r.name.trim().toLowerCase();
    if (name.contains('driver operator') && name.contains('pumper')) {
      return _driverOperatorPumper();
    }
    return const <TaskBookTaskDefinition>[];
  }

  static bool hasTasksForRequirement(Requirement r) =>
      tasksForRequirement(r).isNotEmpty;

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
              subtitle: 'Pump operations practice scenarios'),
          TaskBookPracticeToolLink(
              title: 'Open FireOps Calc',
              route: '/resources?tool=fireops_calc',
              subtitle: 'Friction loss and PDP quick math'),
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
              subtitle: 'Simulated pump panel decisions'),
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
              subtitle: 'Estimate available flow from hydrant data'),
          TaskBookPracticeToolLink(
              title: 'Open FireOps Calc',
              route: '/resources?tool=fireops_calc',
              subtitle: 'PDP + friction loss quick calculations'),
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
              subtitle: 'Drafting scenarios and troubleshooting'),
          TaskBookPracticeToolLink(
              title: 'Open FireOps Calc',
              route: '/resources?tool=fireops_calc',
              subtitle: 'Friction loss + PDP for draft operations'),
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
              subtitle: 'Friction loss + PDP calculator'),
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
              subtitle: 'Multi-line pump ops scenarios'),
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
        commonMistakes: [
          'Underestimating required flow/supply needs',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
              title: 'Open FireOps Calc',
              route: '/resources?tool=fireops_calc',
              subtitle: 'High flow friction loss quick checks'),
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
        safetyPoints: [
          'Monitor line ratings and use relief devices per SOP.',
        ],
        commonMistakes: [
          'Poor communication causing pressure spikes/drops',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
              title: 'Practice in FirePumpSim',
              route: '/resources?tool=firepumpsim',
              subtitle: 'Relay pumping practice'),
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
              subtitle: 'Troubleshooting scenarios'),
        ],
        resources: [],
      ),
    ];
  }
}
