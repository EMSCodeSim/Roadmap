import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';

class CertificationPathwayGuide {
  final String certificationId;
  final String title;
  final String summary;
  final List<String> pathwaySteps;
  final String officialSourceNote;
  final List<TaskBookTaskDefinition> tasks;

  const CertificationPathwayGuide({
    required this.certificationId,
    required this.title,
    required this.summary,
    required this.pathwaySteps,
    required this.officialSourceNote,
    required this.tasks,
  });
}

/// Detailed preparation guides for certifications that need more than a single
/// checklist item in Career Road.
///
/// These guides are original planning/preparation content. They are NOT
/// official JPR sheets and do not replace a state, academy, testing agency, or
/// department task book.
class CertificationGuideLibrary {
  const CertificationGuideLibrary._();

  static CertificationPathwayGuide? guideForRequirement(Requirement requirement) {
    final id = requirement.certificationDefinitionId;
    if (id == 'firefighter_2') return firefighterII;

    final normalized = requirement.name.trim().toLowerCase();
    if (normalized == 'firefighter ii' ||
        normalized == 'fire fighter ii' ||
        normalized == 'firefighter 2' ||
        normalized == 'fire fighter 2') {
      return firefighterII;
    }
    return null;
  }

  static const firefighterII = CertificationPathwayGuide(
    certificationId: 'firefighter_2',
    title: 'Firefighter II',
    summary:
        'Use this as a preparation roadmap for Firefighter II. Career Road breaks the credential into eligibility, training, practical/JPR preparation, testing, and final certification so you can see what to do next instead of treating Firefighter II as one checkbox.',
    pathwaySteps: [
      'Confirm eligibility and prerequisites',
      'Find the approved training/testing path for your state or department',
      'Complete required Firefighter II instruction',
      'Obtain the current official practical/JPR skill sheets',
      'Practice and document the practical skill areas',
      'Complete required written and practical evaluations',
      'Receive the credential and add it to Career Road',
    ],
    officialSourceNote:
        'The skill groups below are preparation categories, not copied official JPR language. Always use the current skill sheets and certification rules published by your state, academy, testing agency, or department.',
    tasks: [
      TaskBookTaskDefinition(
        id: 'ff2_confirm_ff1',
        title: 'Confirm Firefighter I prerequisite',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Confirm that your Firefighter I credential and any locally required prerequisite credentials are current and accepted for the Firefighter II pathway you plan to use.',
        whatToKnow: [
          'Firefighter II commonly builds on Firefighter I, but the exact eligibility rule is set by the certifying authority or department.',
          'Some jurisdictions require affiliation, course completion, or other credentials before testing.',
        ],
        performanceTasks: [
          'Verify your Firefighter I credential in Career Road.',
          'Check the current Firefighter II prerequisite list from the authority that will issue or recognize your credential.',
          'Record any additional prerequisite your department requires as a custom task.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming a credential accepted by one department automatically satisfies another agency or state pathway.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_choose_cert_path',
        title: 'Identify your Firefighter II certification path',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Know exactly who provides the training, who administers testing, and who issues or recognizes the Firefighter II credential in your jurisdiction.',
        whatToKnow: [
          'The training provider, testing agency, and certifying authority may be different organizations.',
          'Department qualification and state certification are not always the same thing.',
        ],
        performanceTasks: [
          'Identify the agency or department whose Firefighter II requirements apply to you.',
          'Save the official certification page or candidate handbook.',
          'Identify how to register for the required course or testing process.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Starting a course before confirming that it leads to the credential your department recognizes.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_get_skill_sheets',
        title: 'Get the current official practical/JPR skill sheets',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Use the exact current evaluation sheets from your certifying or testing authority as the final standard for practical preparation.',
        whatToKnow: [
          'Official practical sheets can change when standards, policies, or testing processes change.',
          'Career Road preparation tasks help organize practice but are not substitutes for official sheets.',
        ],
        performanceTasks: [
          'Download or obtain the current Firefighter II practical/JPR packet.',
          'Confirm the revision date or effective date.',
          'Save the packet where you can reference it during practice.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Practicing from an old photocopy or unofficial checklist without checking the current revision.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_complete_instruction',
        title: 'Complete required Firefighter II instruction',
        section: 'TRAINING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the classroom, online, academy, or department instruction required before evaluation.',
        whatToKnow: [
          'Course-hour and attendance requirements vary by jurisdiction and provider.',
          'Your provider may require assignments, quizzes, labs, or skill sign-offs before testing.',
        ],
        performanceTasks: [
          'Enroll in the approved Firefighter II course or department training pathway.',
          'Complete required instructional modules and attendance requirements.',
          'Keep completion documentation for your Career Record.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Tracking only the final exam and forgetting required course completion documentation.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_command_communications',
        title: 'Command, communications, and incident coordination',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice operating as a more independent firefighter within the incident command structure, including clear reports, assignments, and crew coordination.',
        whatToKnow: [
          'Your department radio procedure and incident command terminology.',
          'How to communicate conditions, needs, progress, and hazards concisely.',
          'Accountability and span-of-control expectations for your role.',
        ],
        performanceTasks: [
          'Give a concise radio report during a simulated incident assignment.',
          'Repeat back an assignment and identify the expected objective.',
          'Report a changing hazard or resource need using department terminology.',
        ],
        safetyPoints: [
          'Do not let radio traffic replace face-to-face crew accountability when conditions require direct confirmation.',
        ],
        commonMistakes: [
          'Long radio transmissions that bury the critical message.',
          'Reporting activity without reporting progress or changing conditions.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Use Firefighter II communication and decision-making drills.',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_fire_attack_support',
        title: 'Advanced fire attack and hose-line operations',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Build competence supporting and operating fire attack lines in more complex assignments while maintaining crew coordination and flow-path awareness.',
        whatToKnow: [
          'Nozzle and hose characteristics used by your department.',
          'Flow path, door control, advancement, backup position, and communications.',
          'When conditions require a change in tactic or withdrawal.',
        ],
        performanceTasks: [
          'Advance and operate the hose package used by your department.',
          'Demonstrate coordinated movement with a nozzle/backup team.',
          'Identify conditions that would require repositioning, withdrawal, or additional resources.',
        ],
        safetyPoints: [
          'Stay coordinated with the crew and maintain a reliable egress path.',
          'Use the department/AHJ live-fire and training safety procedures.',
        ],
        commonMistakes: [
          'Focusing only on nozzle movement and losing crew/door/egress awareness.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Fire attack decision-making drills.',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_search_rescue',
        title: 'Search, rescue, and firefighter support',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice organized search/rescue work, victim removal, orientation, and support of distressed firefighters within your department procedures.',
        whatToKnow: [
          'Primary/secondary search concepts and search orientation methods.',
          'Victim movement options and team communication.',
          'Department procedures for firefighter emergency or rapid intervention support.',
        ],
        performanceTasks: [
          'Complete a structured search while maintaining orientation.',
          'Locate, package, and move a simulated victim using an appropriate technique.',
          'Communicate search progress and significant findings.',
        ],
        safetyPoints: [
          'Maintain crew integrity, air awareness, and egress orientation.',
        ],
        commonMistakes: [
          'Moving too quickly and losing orientation or missing searchable areas.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_ventilation',
        title: 'Ventilation operations and coordination',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice ventilation as a coordinated tactical action rather than an isolated skill.',
        whatToKnow: [
          'Horizontal, vertical, and mechanical ventilation concepts.',
          'How ventilation timing affects fire behavior and interior crews.',
          'Tool, ladder, roof, and fall hazards for the methods your department uses.',
        ],
        performanceTasks: [
          'Select a ventilation method for a training scenario and explain why.',
          'Set up and operate the tools used for the selected method.',
          'Coordinate the ventilation action with the attack/search objective.',
        ],
        safetyPoints: [
          'Follow roof, ladder, saw, and fall-protection procedures applicable to the training evolution.',
        ],
        commonMistakes: [
          'Ventilating without coordination with suppression or command.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Ventilation timing and tactical decision drills.',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_overhaul_property',
        title: 'Overhaul, salvage, and property conservation',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice locating hidden fire while limiting unnecessary damage and preserving evidence when appropriate.',
        whatToKnow: [
          'Hidden-fire indicators and overhaul tool selection.',
          'Salvage covers, water control, and property conservation techniques.',
          'When to protect a potential origin/cause area for investigators.',
        ],
        performanceTasks: [
          'Identify likely hidden-fire locations in a training scenario.',
          'Use appropriate tools to expose an area while controlling damage.',
          'Demonstrate a basic salvage/property conservation action.',
        ],
        safetyPoints: [
          'Continue monitoring structural stability, air quality, utilities, and PPE needs during overhaul.',
        ],
        commonMistakes: [
          'Treating overhaul as a low-risk phase and relaxing PPE or structural awareness too early.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_vehicle_extrication',
        title: 'Vehicle rescue and extrication support',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice stabilization, hazard control, tool use, patient protection, access, and disentanglement within the level expected by your authority or department.',
        whatToKnow: [
          'Scene stabilization and traffic hazards.',
          'Vehicle construction and stored-energy hazards.',
          'Patient protection and communication with EMS/rescue personnel.',
        ],
        performanceTasks: [
          'Stabilize a training vehicle using department equipment.',
          'Identify major vehicle hazards before tool operations.',
          'Demonstrate a supervised access/disentanglement evolution appropriate to your training program.',
        ],
        safetyPoints: [
          'Control traffic, batteries/energy sources, undeployed restraints, glass, sharp edges, and tool reaction forces.',
        ],
        commonMistakes: [
          'Beginning tool work before stabilization and hazard identification are complete.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_prevention_public_ed',
        title: 'Fire prevention, inspections, and public education',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Prepare for Firefighter II responsibilities that extend beyond emergency response, including hazard recognition and public-facing education.',
        whatToKnow: [
          'Common fire/life-safety hazards a firefighter should recognize and report.',
          'Department process for documenting hazards or inspection observations.',
          'Basic public education principles and audience-appropriate communication.',
        ],
        performanceTasks: [
          'Identify common hazards during a simulated occupancy walkthrough.',
          'Document or report findings using the local process.',
          'Deliver a short public education message on a common fire-safety topic.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Presenting personal opinion as code enforcement direction when the firefighter does not have that authority.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_preincident_planning',
        title: 'Preincident planning and building information',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice gathering and communicating useful building, access, hazard, and fire-protection information before an incident occurs.',
        whatToKnow: [
          'What your department includes in a preplan.',
          'Basic building construction, access, utilities, water supply, and fire-protection system considerations.',
        ],
        performanceTasks: [
          'Walk through a training occupancy and identify information useful to responding crews.',
          'Create or update a simple preincident plan using the department format.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Collecting a large amount of information without identifying what responders actually need under time pressure.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_equipment_maintenance',
        title: 'Equipment inspection and maintenance responsibilities',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Demonstrate the ability to inspect, maintain, document, and report fire-service equipment problems within your role.',
        whatToKnow: [
          'Inspection intervals and documentation used by your department.',
          'When equipment should be removed from service and who must be notified.',
        ],
        performanceTasks: [
          'Inspect a selected piece of equipment using the department/manufacturer checklist.',
          'Identify a simulated defect and describe the correct reporting/out-of-service process.',
        ],
        safetyPoints: [
          'Do not return damaged or questionable life-safety equipment to service without following the required inspection process.',
        ],
        commonMistakes: [
          'Treating routine inspection as paperwork instead of a safety function.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_written_exam_prep',
        title: 'Prepare for the written/knowledge evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Prepare for the knowledge evaluation required by your certifying or training authority, if applicable.',
        whatToKnow: [
          'Use the current candidate handbook, course objectives, and authority-provided references to determine what is testable.',
          'Testing format, passing score, retest rules, and identification requirements vary by provider.',
        ],
        performanceTasks: [
          'Confirm the current written-exam rules for your provider.',
          'Build a study plan around the published objectives.',
          'Complete practice questions without treating third-party questions as the official exam blueprint.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Studying only random question banks without checking the current course/test objectives.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Firefighter II review and scenario practice.',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_practical_exam_prep',
        title: 'Prepare for the practical/JPR evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Turn the official practical skill sheets into a deliberate practice plan before the evaluation date.',
        whatToKnow: [
          'Know which practical stations are tested, how stations are selected, and what critical failures or safety requirements apply.',
          'Only the current official evaluator material determines the actual passing criteria.',
        ],
        performanceTasks: [
          'Practice each official skill sheet with an instructor or qualified evaluator.',
          'Identify weak stations and repeat them until performance is consistent.',
          'Complete at least one full mock practical using the actual sequence and equipment available to you.',
        ],
        safetyPoints: [
          'Use qualified instructors and approved training controls for live fire, ladders, saws, vehicles, and other higher-risk evolutions.',
        ],
        commonMistakes: [
          'Memorizing steps without understanding the objective, safety points, and decision cues.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_complete_testing',
        title: 'Complete required Firefighter II testing',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the required knowledge and practical evaluations through the correct testing authority.',
        whatToKnow: [
          'Know registration, identification, equipment/PPE, result, and retest procedures before test day.',
        ],
        performanceTasks: [
          'Register for all required testing components.',
          'Complete the required testing components.',
          'Save official result documentation or completion records.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming course completion automatically means the certification has been issued.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_submit_certification',
        title: 'Complete certification paperwork or issuance steps',
        section: 'CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Finish the administrative steps required for the Firefighter II credential to be issued or recognized.',
        whatToKnow: [
          'Some systems issue automatically after testing; others require an application, department verification, affiliation, fees, or document submission.',
        ],
        performanceTasks: [
          'Confirm whether an application or department authorization is required after testing.',
          'Submit any required documentation.',
          'Verify that the certification has actually been issued or recorded.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Stopping after passing testing and never confirming that the credential was formally issued.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_add_credential',
        title: 'Add Firefighter II credential to Career Road',
        section: 'CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Close the loop by saving the completed credential in Career Road so later career goals recognize it automatically.',
        whatToKnow: [
          'Store the credential name, issuing organization, issue/expiration information if applicable, and supporting document details you want available later.',
        ],
        performanceTasks: [
          'Add Firefighter II to Certifications in Career Road.',
          'Verify it matches the Firefighter II requirement in your active career path.',
          'Retain any evidence or credential document you may need for promotion or transfer later.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Completing the training but failing to add the issued credential, leaving future Roadmap requirements incorrectly shown as incomplete.',
        ],
        practiceTools: [],
        resources: [],
      ),
    ],
  );
}
