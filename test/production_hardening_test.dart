import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/task_book.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/career_stats.dart';
import 'package:firepath/services/local_store.dart';

CareerRecord _record({
  required String id,
  required CareerRecordType type,
  required String title,
  String category = '',
  double? hours,
  int repetitions = 1,
  String? trackingKey,
  String? relatedTaskId,
}) {
  final now = DateTime(2026, 8, 12, 12);
  return CareerRecord(
    id: id,
    type: type,
    title: title,
    category: category,
    date: now,
    roleOrAssignment: null,
    summary: null,
    impact: null,
    evidenceReference: null,
    hours: hours,
    repetitions: repetitions,
    tags: const [],
    relatedGoalId: relatedTaskId == null ? null : 'goal',
    relatedRequirementId: relatedTaskId == null ? null : 'requirement',
    relatedTaskId: relatedTaskId,
    highlight: false,
    trackingKey: trackingKey,
    outcome: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('career record round trip preserves task link and hours', () {
    final original = _record(
      id: 'r1',
      type: CareerRecordType.skill,
      title: 'Drafting',
      category: 'Driver Operator – Pumper',
      hours: 1.5,
      trackingKey: 'quick.drive_time',
      relatedTaskId: 'drafting',
    );

    final restored = CareerRecord.fromJson(original.toJson());

    expect(restored.relatedTaskId, 'drafting');
    expect(restored.relatedRequirementId, 'requirement');
    expect(restored.hours, 1.5);
    expect(restored.trackingKey, 'quick.drive_time');
  });

  test('drive time is not counted as skill repetitions', () {
    final records = [
      _record(
        id: 'drive',
        type: CareerRecordType.skill,
        title: 'Apparatus driving',
        category: 'Driver / Operator',
        hours: 2.5,
        trackingKey: 'quick.drive_time',
      ),
      _record(
        id: 'skill',
        type: CareerRecordType.skill,
        title: 'Ground ladder',
        repetitions: 3,
      ),
    ];

    final stats = CareerStats.fromRecords(records);

    expect(stats.driveHours, 2.5);
    expect(stats.skillRepetitions, 3);
  });

  test('moving a completed task back to practicing clears verification', () {
    final now = DateTime(2026, 8, 12);
    final completed = TaskBookTaskProgress(
      goalId: 'goal',
      requirementId: 'req',
      taskId: 'task',
      status: TaskBookTaskStatus.complete,
      completionSource: TaskBookCompletionSource.selfVerified,
      completedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final practicing = completed.copyWith(
      status: TaskBookTaskStatus.practicing,
      updatedAt: now.add(const Duration(minutes: 1)),
    );

    expect(practicing.status, TaskBookTaskStatus.practicing);
    expect(practicing.completionSource, isNull);
    expect(practicing.completedAt, isNull);
  });

  test('portfolio backup v4 includes Task Book state', () async {
    final local = LocalStore();
    expect(
      await local.saveTaskBookTaskProgress({
        'goal::req::task': {
          'goalId': 'goal',
          'requirementId': 'req',
          'taskId': 'task',
          'status': 'practicing',
        }
      }),
      isTrue,
    );
    expect(
      await local.saveTaskBookCustomTasks([
        {'id': 'custom_task', 'title': 'Department pump practical'}
      ]),
      isTrue,
    );

    final raw = await CareerRecordStore().exportBackup();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    expect(decoded['format'], 'fireops-career-portfolio');
    expect(decoded['version'], 4);
    expect(decoded['taskBookTaskProgress'], isA<Map>());
    expect(decoded['taskBookCustomTasks'], isA<List>());
  });

  test('older portfolio backups remain restorable', () async {
    final raw = jsonEncode({
      'format': 'fireops-career-portfolio',
      'version': 3,
      'onboardingComplete': false,
      'records': <Map<String, dynamic>>[],
      'certifications': <Map<String, dynamic>>[],
      'customRequirements': <Map<String, dynamic>>[],
      'pathOverrides': <Map<String, dynamic>>[],
    });

    final result = await CareerRecordStore().restoreBackup(raw);

    expect(result.success, isTrue);
    expect(result.count, 0);
  });
}
