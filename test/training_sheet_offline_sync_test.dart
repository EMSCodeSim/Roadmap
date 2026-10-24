import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'fireops.responderRoadmap.token.v1': 'qa-isolated-token',
    });
  });

  final observedBatch = <Map<String, dynamic>>[
    for (var index = 0; index < 10; index++)
      <String, dynamic>{
        'enrollmentId': 'member-${index + 1}',
        'result': index < 8 ? 'PASS' : (index == 8 ? 'FAIL' : 'NEEDS_REMEDIATION'),
        'notes': index < 8 ? '' : 'Individual remediation',
        'expectedUpdatedAt': null,
      },
  ];

  test('closeout sends PATCH with actual times and narrative', () async {
    String? method;
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      method = request.method;
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.url.path, '/api/v1/app/training-sheets/class-10/documentation');
      return http.Response(jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 'class-10',
          'startsAt': '2026-10-23T14:00:00.000Z',
          'endsAt': '2026-10-23T15:30:00.000Z',
          'notes': 'Ten-member training. RMS code EMS-TRAIN',
          'status': 'ACTIVE',
        },
      }), 200);
    });
    final api = ResponderRoadmapApi(client: client);
    final result = await api.updateTrainingSheetDocumentation(
      'class-10',
      startsAt: DateTime.utc(2026, 10, 23, 14),
      endsAt: DateTime.utc(2026, 10, 23, 15, 30),
      notes: 'Ten-member training. RMS code EMS-TRAIN',
      location: 'Training station',
      creditHours: 1.5,
    );
    expect(method, 'PATCH');
    expect(sent?['creditHours'], 1.5);
    expect(sent?['endsAt'], '2026-10-23T15:30:00.000Z');
    expect(result.endsAt, isNotNull);
    expect(result.notes, contains('EMS-TRAIN'));
  });

  test('ten-member offline batch is stored and replayed with expected revisions', () async {
    var online = false;
    var submitted = 0;
    final client = MockClient((request) async {
      if (!online) throw const SocketException('offline');
      submitted++;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/app/training-sheets/class-10/skills/batch');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>;
      expect(results.length, 10);
      expect(results.every((value) =>
          (value as Map<String, dynamic>).containsKey('expectedUpdatedAt')), isTrue);
      expect(results.where((value) => (value as Map)['result'] == 'PASS').length, 8);
      expect(results.where((value) => (value as Map)['result'] == 'FAIL').length, 1);
      return http.Response('{"data":{"id":"class-10","status":"ACTIVE"}}', 200);
    });
    final api = ResponderRoadmapApi(client: client);
    final queued = await api.recordClassSkillBatchDurable(
      classId: 'class-10', requirementId: 'skill-1', results: observedBatch,
    );
    expect(queued.queued, isTrue);
    expect(queued.detail, isNull);
    expect(await api.pendingSkillMutationCountForClass('class-10'), 1);
    online = true;
    expect(await api.retryPendingClassMutations(), 1);
    expect(submitted, 1);
    expect(await api.pendingSkillMutationCountForClass('class-10'), 0);
    expect(await api.retryPendingClassMutations(), 0);
    expect(submitted, 1);
  });

  test('offline conflict is preserved for instructor review, never auto-overwritten', () async {
    var online = false;
    var attempts = 0;
    final client = MockClient((request) async {
      if (!online) throw const SocketException('offline');
      attempts++;
      return http.Response('{"error":"Skill results have changed. Refresh and reconcile."}', 409);
    });
    final api = ResponderRoadmapApi(client: client);
    final queued = await api.recordClassSkillBatchDurable(
      classId: 'class-10', requirementId: 'skill-1', results: observedBatch,
    );
    expect(queued.queued, isTrue);
    online = true;
    expect(await api.retryPendingClassMutations(), 0);
    expect(attempts, 1);
    expect(await api.pendingSkillConflictCountForClass('class-10'), 1);
    expect(await api.retryPendingClassMutations(), 0);
    expect(attempts, 1, reason: '409 conflict must not replay repeatedly');
    final rows = await api.pendingSkillMutationsForClass('class-10');
    expect(rows.single['syncStatus'], 'CONFLICT');
    expect((rows.single['results'] as List).length, 10);
    await api.discardReviewedSkillMutation('class-10', rows.single['key'] as String);
    expect(await api.pendingSkillMutationCountForClass('class-10'), 0);
  });

  test('unversioned skill batch is rejected before any network request', () async {
    var requests = 0;
    final api = ResponderRoadmapApi(client: MockClient((request) async {
      requests++;
      return http.Response('{}', 200);
    }));
    await expectLater(
      api.recordClassSkillBatchDurable(
        classId: 'class-10',
        results: <Map<String, dynamic>>[
          <String, dynamic>{'enrollmentId': 'member-1', 'result': 'PASS'},
        ],
      ),
      throwsA(isA<ResponderRoadmapApiException>()),
    );
    expect(requests, 0);
    expect(await api.pendingSkillMutationCountForClass('class-10'), 0);
  });
}
