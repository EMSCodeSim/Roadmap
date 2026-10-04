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
        id: 'ff2_confirm_required_jprs',
        title: 'Confirm the required official JPRs',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Build your checklist from the current official Firefighter II practical/JPR packet before you start checking off skill mastery.',
        whatToKnow: [
          'The number, order, wording, and critical criteria of official JPRs can vary by authority and revision.',
          'Responder Roadmap should organize the official requirements, not invent them.',
        ],
        performanceTasks: [
          'Open the current official Firefighter II JPR/practical packet.',
          'Confirm the revision or effective date.',
          'Identify every JPR or practical station you may be required to complete.',
          'Add any locally specific JPRs or stations to this Task Book as custom tasks.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Using an old academy checklist or another state’s JPR packet without confirming that it applies.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_confirm_required_reading',
        title: 'Confirm required reading and reference material',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Identify the exact textbook chapters, candidate handbook sections, standards, policies, and other material your course or testing authority expects you to study.',
        whatToKnow: [
          'Required chapters and reference editions vary by course and testing provider.',
          'A general study guide should not replace the official reading list.',
        ],
        performanceTasks: [
          'Confirm the required textbook title and edition.',
          'Confirm the assigned chapters or modules.',
          'Confirm any candidate handbook, policy, standard, or supplemental reading.',
          'Add each major reading assignment to this Task Book as a custom task when you want a separate checkbox for it.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Studying from the right textbook but the wrong edition or skipping provider-assigned chapters.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_build_mastery_checklist',
        title: 'Build the JPR mastery checklist',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Turn the official JPR packet into a set of individual practice targets so each required station can be mastered and checked off separately.',
        whatToKnow: [
          'Use the exact official JPR names or station identifiers when adding custom mastery tasks.',
          'Mastery in Responder Roadmap is preparation status; only the official evaluator or testing authority determines a passing result.',
        ],
        performanceTasks: [
          'Create a separate custom Task Book item for each official JPR or station.',
          'Use a consistent name such as “Master JPR — [official station name]”.',
          'Mark each mastery item complete only after you can perform it consistently to the current official criteria.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Treating one successful practice attempt as mastery.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_build_reading_checklist',
        title: 'Build the reading checklist',
        section: 'PLAN THE CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Break the official reading assignment into small checkoffs so required material is not lost inside one large “study” task.',
        whatToKnow: [
          'Examples could be “Read Chapter 3,” “Read Chapter 4,” or “Review candidate handbook testing rules,” but only add material your provider actually requires.',
        ],
        performanceTasks: [
          'Create one custom task per assigned chapter, module, or required reference section.',
          'Complete each reading item and note any weak topics that need review.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Checking off reading based on a summary without completing required source material.',
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
        title: 'Master practice area — command and communications',
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
        title: 'Master practice area — fire attack and hose operations',
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
        title: 'Master practice area — search and rescue',
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
        title: 'Master practice area — ventilation',
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
        title: 'Master practice area — overhaul and property conservation',
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
        title: 'Master practice area — vehicle rescue/extrication',
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
        title: 'Master practice area — prevention and public education',
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
        title: 'Master practice area — preincident planning',
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
        title: 'Master practice area — equipment inspection/maintenance',
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
        id: 'ff2_find_test_location',
        title: 'Find an approved testing location',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Identify where your written and practical Firefighter II testing can be completed through the authority that applies to you.',
        whatToKnow: [
          'Written and practical testing may occur at different locations or through different providers.',
          'Confirm that the site is approved for the credential pathway your department recognizes.',
        ],
        performanceTasks: [
          'Find an approved written-test location or provider.',
          'Find an approved practical/JPR evaluation location or provider.',
          'Save contact information and testing instructions.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Registering with a convenient provider before confirming that the result is accepted by the certifying authority.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_confirm_test_dates_fees',
        title: 'Confirm test dates, deadlines, fees, and required documents',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Know the logistics before registration so no administrative detail delays testing.',
        whatToKnow: [
          'Testing providers may require proof of prerequisites, course completion, identification, PPE/equipment, affiliation, or payment.',
        ],
        performanceTasks: [
          'Confirm the next available written and practical dates.',
          'Record registration deadlines.',
          'Confirm fees and cancellation/retest policies.',
          'Gather required identification, course completion, prerequisite, or affiliation documentation.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Waiting until test week to discover missing prerequisite documentation.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_register_written',
        title: 'Register for the written test',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the official registration step for the Firefighter II written/knowledge examination.',
        whatToKnow: [
          'Confirm the appointment, location or remote-testing rules, identification requirements, and rescheduling policy.',
        ],
        performanceTasks: [
          'Submit the required registration or application.',
          'Pay any required fee.',
          'Save the confirmation and test date.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming course enrollment automatically registers you for the certification exam.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'ff2_register_practical',
        title: 'Register for the practical/JPR test',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the official registration or scheduling step for the Firefighter II practical/JPR evaluation.',
        whatToKnow: [
          'Confirm which equipment/PPE you must provide and whether station assignments are known in advance.',
        ],
        performanceTasks: [
          'Submit the required registration or scheduling request.',
          'Confirm location, arrival time, PPE/equipment requirements, and evaluator instructions.',
          'Save the confirmation and test date.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Preparing for the skills but forgetting the provider-specific check-in or equipment requirements.',
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
