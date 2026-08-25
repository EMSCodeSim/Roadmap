import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/task_book.dart';

class AdvancedCertificationGuideData {
  final String certificationId;
  final String title;
  final String summary;
  final List<String> pathwaySteps;
  final String officialSourceNote;
  final List<TaskBookTaskDefinition> tasks;

  const AdvancedCertificationGuideData({
    required this.certificationId,
    required this.title,
    required this.summary,
    required this.pathwaySteps,
    required this.officialSourceNote,
    required this.tasks,
  });

  static AdvancedCertificationGuideData? forRequirement(Requirement requirement) {
    final id = requirement.certificationDefinitionId;
    if (id == 'driver_operator_pumper') return driverOperatorPumper;
    if (id == 'fire_officer_1') return fireOfficerI;

    final name = requirement.name.trim().toLowerCase();
    if ((name.contains('driver') || name.contains('engineer')) &&
        (name.contains('pumper') || name.contains('operator'))) {
      return driverOperatorPumper;
    }
    if (name == 'fire officer i' ||
        name == 'fire officer 1' ||
        name == 'officer i' ||
        name == 'company officer i') {
      return fireOfficerI;
    }
    return null;
  }

  static const driverOperatorPumper = AdvancedCertificationGuideData(
    certificationId: 'driver_operator_pumper',
    title: 'Driver/Operator – Pumper',
    summary:
        'Use this pathway to organize the complete Driver/Operator – Pumper process: eligibility, approved training, apparatus and pump practice, official practical/JPR preparation, testing, and credential issuance. Existing pump-operation tasks remain part of the practical preparation layer.',
    pathwaySteps: [
      'Confirm license, firefighter, and department prerequisites',
      'Identify the state/department Driver/Operator certification path',
      'Obtain the current official practical/JPR skill sheets',
      'Complete required driver/operator instruction',
      'Build documented driving, apparatus, water-supply, and pump competency',
      'Complete required written and practical evaluations',
      'Receive the credential and add it to Career Road',
    ],
    officialSourceNote:
        'Career Road preparation tasks are not official evaluator sheets. Driving, emergency vehicle operation, pump operations, and practical testing must follow the current rules, apparatus procedures, skill sheets, and safety requirements of your state, department, academy, testing agency, and vehicle manufacturer.',
    tasks: [
      TaskBookTaskDefinition(
        id: 'do_confirm_prereqs',
        title: 'Confirm Driver/Operator prerequisites',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Verify every prerequisite before investing time in a Driver/Operator course or test process.',
        whatToKnow: [
          'Prerequisites vary and may include Firefighter certification, department affiliation, minimum driving experience, an acceptable motor vehicle record, a specific license class, EVOC/emergency vehicle training, or medical requirements.',
        ],
        performanceTasks: [
          'Confirm the current prerequisite list with the certifying authority and your department.',
          'Verify your driver license and any required emergency vehicle credential.',
          'Add department-only prerequisites as custom tasks.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming a state certification automatically authorizes driving every department apparatus.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_choose_path',
        title: 'Identify the approved Driver/Operator pathway',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Know who provides training, who tests you, and who issues or recognizes the credential.',
        whatToKnow: [
          'State certification, academy completion, and department engineer qualification may be separate processes.',
        ],
        performanceTasks: [
          'Save the official certification or candidate page.',
          'Identify the required course and testing provider.',
          'Confirm whether department sign-offs or drive-time minimums are required in addition to certification.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Completing a pump class that does not satisfy the qualification path your department uses.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_get_skill_sheets',
        title: 'Get current Driver/Operator practical/JPR sheets',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Use the current official evaluation material as the final standard for practical preparation.',
        whatToKnow: [
          'Practical packets and evaluator criteria can change.',
          'Career Road organizes practice but does not replace official skill sheets.',
        ],
        performanceTasks: [
          'Obtain the current practical/JPR packet.',
          'Confirm its revision/effective date.',
          'Compare every official station with the preparation tasks in Career Road.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Using an old department photocopy without confirming the current testing revision.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_complete_instruction',
        title: 'Complete required Driver/Operator instruction',
        section: 'TRAINING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the approved classroom and hands-on instruction required before evaluation.',
        whatToKnow: [
          'Training commonly covers emergency vehicle safety, apparatus inspection, positioning, water supply, pump theory, hydraulic calculations, pumping operations, and troubleshooting.',
        ],
        performanceTasks: [
          'Complete the approved course or department program.',
          'Retain course-completion documentation.',
          'Log supervised driving and pump practice when your department requires it.',
        ],
        safetyPoints: [
          'Hands-on driving and pump evolutions must be conducted under department training controls with qualified instructors.',
        ],
        commonMistakes: [
          'Focusing on pump math while under-practicing vehicle positioning and safe apparatus movement.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice pump decisions in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Pump operations and troubleshooting scenarios',
          ),
          TaskBookPracticeToolLink(
            title: 'Practice hydraulics in FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'Friction loss, PDP, water supply, and related calculations',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_driving_competency',
        title: 'Build supervised emergency vehicle driving competency',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Develop repeatable apparatus-control habits before evaluation or independent assignment.',
        whatToKnow: [
          'Department driving policy, intersection procedure, backing policy, spotter use, speed limitations, braking distance, apparatus dimensions, and route/positioning considerations.',
        ],
        performanceTasks: [
          'Complete supervised non-emergent driving in the apparatus type you will operate.',
          'Practice backing and close-quarter maneuvering using department spotter procedures.',
          'Practice safe positioning for common incident types.',
          'Document required drive time or evaluator sign-offs when applicable.',
        ],
        safetyPoints: [
          'Never use Career Road or a simulator as authorization to perform emergency driving outside department policy and instructor supervision.',
        ],
        commonMistakes: [
          'Treating cone-course performance as a substitute for judgment, scanning, and positioning on real roadways.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_written_prep',
        title: 'Prepare for the Driver/Operator knowledge evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Prepare from the current published course objectives and candidate information.',
        whatToKnow: [
          'Know the current testing format, required references, passing score, retest rules, and any calculation expectations.',
        ],
        performanceTasks: [
          'Build a study plan from the authority-provided objectives.',
          'Practice hydraulic calculations and apparatus-operation decision questions.',
          'Confirm testing-day requirements before the exam.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Memorizing formulas without understanding when the calculation applies operationally.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Open FireOps Calc',
            route: '/resources?tool=fireops_calc',
            subtitle: 'Hydraulic calculation practice',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_practical_prep',
        title: 'Prepare for the Driver/Operator practical evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice each official station until apparatus movement, positioning, water supply, and pump operations are consistent and safe.',
        whatToKnow: [
          'Only the current official evaluator material determines actual passing criteria and critical failures.',
        ],
        performanceTasks: [
          'Practice every official station with a qualified instructor/evaluator.',
          'Complete a full mock practical using the apparatus and equipment expected for testing.',
          'Repeat weak stations until performance is consistent rather than memorized once.',
        ],
        safetyPoints: [
          'Use approved training areas, traffic controls, spotters, PPE, and apparatus procedures.',
        ],
        commonMistakes: [
          'Trying to rush a sequence instead of demonstrating control, communication, and confirmation.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FirePumpSim',
            route: '/resources?tool=firepumpsim',
            subtitle: 'Pump-panel decision practice before hands-on evaluation',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_complete_testing',
        title: 'Complete required Driver/Operator testing',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete all required knowledge and practical components through the correct authority.',
        whatToKnow: [],
        performanceTasks: [
          'Register for all required testing components.',
          'Complete required knowledge and practical evaluations.',
          'Save official result documentation.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming passing a course automatically means the credential or department qualification has been issued.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'do_issue_credential',
        title: 'Complete credential and department qualification steps',
        section: 'CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Close both the certification and local qualification loops before treating the Driver/Operator step as complete.',
        whatToKnow: [
          'Your department may require apparatus-specific sign-off, probationary engineer time, or additional driving/pumping evaluations after outside certification.',
        ],
        performanceTasks: [
          'Confirm the credential was issued or recorded.',
          'Complete any remaining department apparatus/engineer sign-offs.',
          'Add the issued credential to Career Road and retain supporting documentation.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Confusing certification with authorization to independently operate every apparatus.',
        ],
        practiceTools: [],
        resources: [],
      ),
    ],
  );

  static const fireOfficerI = AdvancedCertificationGuideData(
    certificationId: 'fire_officer_1',
    title: 'Fire Officer I',
    summary:
        'Use this mini task book to move from experienced firefighter to first-line company officer preparation. It separates eligibility and training from practical leadership/JPR preparation, testing, and final credential issuance so the user can see the actual work between “need Officer I” and “have Officer I.”',
    pathwaySteps: [
      'Confirm firefighter, experience, incident-command, and local prerequisites',
      'Identify the approved Fire Officer I training/certification path',
      'Obtain the current official practical/JPR or candidate materials',
      'Complete required Fire Officer I instruction',
      'Practice first-line supervision, communication, administration, training, prevention, and incident leadership',
      'Complete required written and practical evaluations',
      'Receive the credential and add it to Career Road',
    ],
    officialSourceNote:
        'The Officer I skill groups below are original preparation categories, not copied official JPR wording. Actual eligibility, experience requirements, evaluation stations, authority limits, and passing criteria come from the current state, academy, testing agency, and department materials.',
    tasks: [
      TaskBookTaskDefinition(
        id: 'fo1_confirm_prereqs',
        title: 'Confirm Fire Officer I prerequisites',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Verify the certifications, service experience, incident-command training, department eligibility, and other prerequisites that apply before beginning the credential process.',
        whatToKnow: [
          'Officer eligibility varies widely. Some systems require specific firefighter certifications, instructor training, incident-command courses, years of experience, or department affiliation.',
        ],
        performanceTasks: [
          'Confirm the current prerequisite list from the authority that will issue or recognize Fire Officer I.',
          'Compare the list with Certifications and Career Record in Career Road.',
          'Add department-specific experience or promotional prerequisites as custom tasks.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Treating Fire Officer I certification as identical to eligibility for Lieutenant or Captain in a specific department.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_choose_path',
        title: 'Identify the approved Fire Officer I pathway',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Know who teaches, tests, and issues or recognizes the credential.',
        whatToKnow: [
          'A department promotional process may sit on top of the certification process and include separate written exams, assessment centers, interviews, or acting-officer expectations.',
        ],
        performanceTasks: [
          'Save the current official certification/candidate page.',
          'Identify the required course and testing pathway.',
          'Document any separate department promotional requirements.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Completing a generic leadership course without confirming it satisfies the recognized Officer I pathway.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_get_skill_sheets',
        title: 'Get current Officer I practical/JPR materials',
        section: 'GETTING STARTED',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Use current evaluator/candidate material as the final standard for practical preparation.',
        whatToKnow: [
          'Officer practical evaluations often involve written products, presentations, supervisory conversations, training activities, inspections/preplans, or incident scenarios rather than only hands-on fireground skills.',
        ],
        performanceTasks: [
          'Obtain the current practical/JPR or candidate packet.',
          'Confirm revision/effective dates.',
          'List every required deliverable or station in your Career Road preparation plan.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Preparing only for a written exam and overlooking required practical documents or presentations.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_complete_instruction',
        title: 'Complete required Fire Officer I instruction',
        section: 'TRAINING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete the approved instruction required for first-line officer certification or qualification.',
        whatToKnow: [
          'Instruction commonly includes supervision, communication, company-level administration, training, community risk/prevention, emergency service delivery, safety, and incident leadership.',
        ],
        performanceTasks: [
          'Complete the approved Officer I course or department pathway.',
          'Save completion documentation.',
          'Log acting-officer, mentoring, teaching, project, or leadership experiences that support later promotion preparation.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Treating the course as the whole development process instead of building real supervisory and decision-making experience.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Officer I leadership, communication, and incident decision drills',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_supervision',
        title: 'Supervision, coaching, and conflict management',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice first-line supervision that sets expectations, corrects performance, documents appropriately, and maintains a professional crew climate.',
        whatToKnow: [
          'Department policy, chain of command, progressive discipline concepts, documentation expectations, coaching, and when an issue must be elevated.',
        ],
        performanceTasks: [
          'Conduct a simulated performance/coaching conversation.',
          'Address a crew conflict scenario while separating facts, policy, and assumptions.',
          'Write a concise factual supervisory note or follow-up summary using department expectations.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Avoiding difficult conversations until a small performance issue becomes a larger crew problem.',
          'Documenting emotion or conclusions instead of observable facts and actions.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Company officer personnel and leadership scenarios',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_company_admin',
        title: 'Company-level administration and written communication',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Build the routine administrative skills expected of a first-line officer.',
        whatToKnow: [
          'Department forms, records, reports, scheduling/assignment practices, policy communication, and routing through the chain of command.',
        ],
        performanceTasks: [
          'Prepare a professional email or memo communicating a company-level issue.',
          'Complete a simulated incident/training/personnel record using local standards.',
          'Prioritize a shift workload containing operational, training, equipment, and personnel responsibilities.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Writing more than needed while failing to state the decision, action, owner, or deadline clearly.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_training_delivery',
        title: 'Plan and deliver company training',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice identifying a training need, building a safe objective-based drill, delivering it, and documenting results.',
        whatToKnow: [
          'Learning objectives, lesson/drill planning, risk controls, adapting instruction, evaluation, and training documentation.',
        ],
        performanceTasks: [
          'Create a short company drill from an identified performance need.',
          'State measurable objectives and safety controls.',
          'Deliver or simulate the drill and document attendance/results.',
        ],
        safetyPoints: [
          'Training risk controls must match the actual evolution, equipment, environment, and department policy.',
        ],
        commonMistakes: [
          'Choosing an activity first and inventing the learning objective afterward.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_incident_leadership',
        title: 'Initial incident leadership and company operations',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice making and communicating safe first-line decisions during the early phase of incidents.',
        whatToKnow: [
          'Department command system, initial radio report, risk assessment, strategy/tactics, crew accountability, resource requests, transfer of command, and progress reports.',
        ],
        performanceTasks: [
          'Give an initial radio report from a simulated incident.',
          'Set an initial operational objective and assign a company-level task.',
          'Identify changing conditions that require tactical adjustment, additional resources, or withdrawal.',
          'Give a concise progress report and transfer command when appropriate.',
        ],
        safetyPoints: [
          'Scenario practice does not replace department command training or authorization to act outside assigned authority.',
        ],
        commonMistakes: [
          'Giving a polished initial report but failing to reassess conditions after operations begin.',
          'Assigning tasks without confirming objective, location, resources, and accountability.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice Officer I incidents in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Initial command, communication, and company decision scenarios',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_safety_risk',
        title: 'Crew safety, risk recognition, and corrective action',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Practice recognizing unsafe conditions or behaviors and taking an appropriate first-line officer action.',
        whatToKnow: [
          'Department safety policy, near-miss reporting, PPE/SCBA expectations, accountability, rehabilitation, exposure reporting, and stop-work/escalation expectations.',
        ],
        performanceTasks: [
          'Evaluate a simulated unsafe crew or station condition.',
          'State the immediate corrective action and longer-term follow-up.',
          'Document/escalate the issue using the appropriate local process.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Correcting the individual action but failing to address the equipment, training, staffing, or system issue behind it.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_prevention_preplan',
        title: 'Prevention, inspection, and preincident planning responsibilities',
        section: 'PRACTICAL / JPR PREPARATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Prepare for company-officer responsibilities involving occupancy information, hazard recognition, public contact, and preincident planning.',
        whatToKnow: [
          'Your department role in inspections, referrals, public education, preplans, water supply, access, fire protection systems, and documenting hazards.',
        ],
        performanceTasks: [
          'Conduct a simulated company-level occupancy walkthrough.',
          'Identify operationally important hazards and fire-protection features.',
          'Create or update a simple preincident plan using the department format.',
          'Explain when a condition should be referred to prevention/code personnel.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Acting outside the officer/company authority instead of recognizing, documenting, and referring an issue appropriately.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_written_prep',
        title: 'Prepare for the Officer I knowledge evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Prepare from the current published objectives and candidate material.',
        whatToKnow: [
          'Know the current testing format, references, passing score, retest rules, and documentation requirements.',
        ],
        performanceTasks: [
          'Build a study plan from published objectives.',
          'Practice applying policy and leadership concepts to scenarios rather than memorizing definitions only.',
          'Confirm test-day requirements.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Studying only fireground command while neglecting personnel, administration, training, prevention, and organizational responsibilities.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Officer I review and scenario practice',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_practical_prep',
        title: 'Prepare for the Officer I practical/JPR evaluation',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Turn every official evaluator station or deliverable into deliberate practice before test day.',
        whatToKnow: [
          'Officer practicals may require both verbal performance and written work products. Only current official materials determine actual passing criteria.',
        ],
        performanceTasks: [
          'Practice each official station with a qualified instructor/evaluator.',
          'Complete mock written products and presentations under realistic time limits.',
          'Complete a full mock practical/assessment sequence and review weak areas.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Sounding confident in a scenario without clearly stating policy basis, decision, communication, documentation, and follow-up.',
        ],
        practiceTools: [
          TaskBookPracticeToolLink(
            title: 'Practice in FireOpsSim',
            route: '/resources?tool=fireopssim',
            subtitle: 'Officer decision-making scenarios before practical evaluation',
          ),
        ],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_complete_testing',
        title: 'Complete required Fire Officer I testing',
        section: 'TESTING',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete all required knowledge and practical evaluation components.',
        whatToKnow: [],
        performanceTasks: [
          'Register for all required testing components.',
          'Complete required evaluations.',
          'Save official result documentation.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Assuming passing a class means the credential has already been issued.',
        ],
        practiceTools: [],
        resources: [],
      ),
      TaskBookTaskDefinition(
        id: 'fo1_issue_credential',
        title: 'Complete Fire Officer I credential issuance',
        section: 'CERTIFICATION',
        goalId: null,
        requirementId: null,
        isCustom: false,
        fireOpsObjective:
            'Complete any application, verification, affiliation, documentation, or issuance steps after testing.',
        whatToKnow: [
          'Certification issuance and department promotion/appointment are separate unless your local process explicitly combines them.',
        ],
        performanceTasks: [
          'Confirm the credential was formally issued or recorded.',
          'Add Fire Officer I to Career Road Certifications.',
          'Retain supporting documents and connect relevant leadership/training evidence to your Career Record.',
        ],
        safetyPoints: [],
        commonMistakes: [
          'Treating the certification itself as proof of promotion readiness without building experience and evidence.',
        ],
        practiceTools: [],
        resources: [],
      ),
    ],
  );
}
