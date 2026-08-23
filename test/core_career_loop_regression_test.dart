import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/career_inbox.dart';
import 'package:firepath/services/career_pdf_export.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/editable_promotion_portfolio.dart';
import 'package:firepath/services/ecosystem_recommendations.dart';
import 'package:firepath/services/task_book_library.dart';
import 'package:firepath/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  UserProfile profile() {
    final now = DateTime(2026, 8, 23, 12);
    return UserProfile(
      currentRoles: const ['Firefighter'],
      primaryGoalId: null,
      targetDate: null,
      careerPlan: CareerPlan.empty(),
      yearsOfService: 6,
      serviceType: 'Career',
      departmentName: 'Test Fire Department',
      state: 'CO',
      createdAt: now,
      updatedAt: now,
    );
  }

  Certification cert(String name) {
    final now = DateTime(2026, 8, 23, 12);
    return Certification(
      id: 'cert_${name.replaceAll(' ', '_')}',
      name: name,
      certificationDefinitionId: null,
      issuingOrganization: null,
      certificationNumber: null,
      issueDate: null,
      expirationDate: null,
      doesNotExpire: true,
      notes: null,
      renewalHistory: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<AppState> buildEngineerState() async {
    final state = AppState();
    await state.bootstrap();
    await state.completeOnboarding(
      profile: profile(),
      certifications: [
        cert('Firefighter I'),
        cert('Firefighter II'),
        cert('HazMat Operations'),
      ],
    );
    await state.setPrimaryGoal('ops_engineer');
    return state;
  }

  ({dynamic requirement, TaskBookTaskDefinition task}) firstTask(AppState state) {
    final roadmap = state.roadmap!;
    final item = roadmap.all.firstWhere(
      (entry) => TaskBookLibrary.hasTasksForRequirement(entry.requirement),
    );
    final task = TaskBookLibrary.tasksForRequirement(item.requirement).first;
    return (requirement: item.requirement, task: task);
  }

  CareerRecord completedTaskRecord({
    required String goalId,
    required String requirementId,
    required TaskBookTaskDefinition task,
  }) {
    final now = DateTime(2026, 8, 23, 12);
    return CareerRecord(
      id: 'career_${task.id}',
      type: CareerRecordType.taskBookEvidence,
      title: task.title,
      category: 'Driver / Operator',
      date: now,
      roleOrAssignment: 'Candidate',
      summary: 'Completed the Task Book evolution and documented the work.',
      impact: 'Demonstrated the required skill and preserved it for promotion evidence.',
      evidenceReference: null,
      hours: 1,
      repetitions: 1,
      tags: const ['task-book', 'completed'],
      relatedGoalId: goalId,
      relatedRequirementId: requirementId,
      relatedTaskId: task.id,
      highlight: true,
      trackingKey: null,
      outcome: CareerRecordOutcome.completed,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('goal -> Task Book -> completion survives app restart', () async {
    final state = await buildEngineerState();
    final selected = firstTask(state);
    final goalId = state.roadmap!.goal.id;

    await state.setTaskStatus(
      goalId: goalId,
      requirementId: selected.requirement.id,
      taskId: selected.task.id,
      status: TaskBookTaskStatus.complete,
      completionSource: TaskBookCompletionSource.selfVerified,
    );

    expect(
      state.taskStatusFor(
        goalId: goalId,
        requirementId: selected.requirement.id,
        taskId: selected.task.id,
      ),
      TaskBookTaskStatus.complete,
    );

    final restarted = AppState();
    await restarted.bootstrap();

    expect(restarted.selectedGoal?.id, 'ops_engineer');
    expect(
      restarted.taskStatusFor(
        goalId: goalId,
        requirementId: selected.requirement.id,
        taskId: selected.task.id,
      ),
      TaskBookTaskStatus.complete,
    );
    expect(
      restarted.taskProgressFor(
        goalId: goalId,
        requirementId: selected.requirement.id,
        taskId: selected.task.id,
      )?.completionSource,
      TaskBookCompletionSource.selfVerified,
    );
  });

  test('completed Task Book item stays in Career Inbox until career record exists', () async {
    final state = await buildEngineerState();
    final selected = firstTask(state);
    final goalId = state.roadmap!.goal.id;

    await state.setTaskStatus(
      goalId: goalId,
      requirementId: selected.requirement.id,
      taskId: selected.task.id,
      status: TaskBookTaskStatus.complete,
      completionSource: TaskBookCompletionSource.selfVerified,
    );

    final before = CareerInbox.build(app: state, records: const []);
    expect(
      before.any(
        (item) =>
            item.kind == CareerInboxKind.undocumentedCompletion &&
            item.task?.id == selected.task.id,
      ),
      isTrue,
    );

    final record = completedTaskRecord(
      goalId: goalId,
      requirementId: selected.requirement.id,
      task: selected.task,
    );
    expect(await CareerRecordStore().upsert(record), isTrue);
    final records = await CareerRecordStore().load();

    final after = CareerInbox.build(app: state, records: records);
    expect(
      after.any(
        (item) =>
            item.kind == CareerInboxKind.undocumentedCompletion &&
            item.task?.id == selected.task.id,
      ),
      isFalse,
    );
    expect(records.single.relatedTaskId, selected.task.id);
  });

  test('Daily Focus handoff keeps certification context in FireOpsSim URL', () {
    final recommendation = EcosystemRecommendations.forDailyFocus(
      topic: 'Coordinated ventilation',
      qualification: 'Firefighter II',
      goal: 'Company Officer',
    );

    expect(recommendation, isNotNull);
    expect(recommendation!.product, 'FireOpsSim');
    final uri = Uri.parse(recommendation.url);
    expect(uri.host, 'fireopssim.com');
    expect(uri.path, '/focus-drills.html');
    expect(uri.queryParameters['source'], 'roadmap');
    expect(uri.queryParameters['level'], 'firefighter_2');
    expect(uri.queryParameters['topic'], 'Coordinated ventilation');
  });

  test('career record -> editable promotion draft -> PDF remains exportable', () async {
    final state = await buildEngineerState();
    final selected = firstTask(state);
    final record = completedTaskRecord(
      goalId: state.roadmap!.goal.id,
      requirementId: selected.requirement.id,
      task: selected.task,
    );
    final records = [record];

    final draft = EditablePromotionPortfolio.defaultDraft(
      app: state,
      records: records,
    );

    expect(draft.executiveSummary, isNotEmpty);
    expect(draft.accomplishmentIds, contains(record.id));
    expect(draft.storyIds, contains(record.id));

    final bytes = await EditablePromotionPortfolio.buildPdf(
      app: state,
      records: records,
      identity: const CareerExportIdentity(
        name: 'Test Candidate',
        email: 'candidate@example.com',
        phone: '555-0100',
        location: 'Denver, CO',
      ),
      draft: draft,
    );

    expect(bytes.length, greaterThan(1000));
    expect(bytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]);
  });
}
