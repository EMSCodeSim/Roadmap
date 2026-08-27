import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_backup_service.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/storage/file_json_store_io.dart';
import 'package:firepath/services/storage/path_bytes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('backup file names are dated and stable', () {
    expect(
      CareerBackupService.fileNameFor(DateTime(2026, 8, 27)),
      'FireOps-Career-Portfolio-2026-08-27.json',
    );
  });

  test('LocalStore migrates SharedPreferences JSON into the documents file store',
      () async {
    SharedPreferences.setMockInitialValues({
      'fireops.profile': jsonEncode({'departmentName': 'Station 1'}),
    });
    final dir = await Directory.systemTemp.createTemp('fireops_store');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalStore(
      fileStore: PlatformFileJsonStore(rootPath: dir.path),
    );

    final profile = await store.loadProfile();
    expect(profile?['departmentName'], 'Station 1');

    final file = File('${dir.path}/fireops.profile.json');
    expect(await file.exists(), isTrue);
    expect(file.readAsStringSync(), contains('Station 1'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('fireops.profile'), isNull);
  });

  test('career records survive a new LocalStore pointed at the same files',
      () async {
    final dir = await Directory.systemTemp.createTemp('fireops_records');
    addTearDown(() => dir.delete(recursive: true));
    final store = CareerRecordStore(
      store: LocalStore(fileStore: PlatformFileJsonStore(rootPath: dir.path)),
    );

    final now = DateTime(2026, 8, 27, 12);
    final record = CareerRecord(
      id: 'r1',
      type: CareerRecordType.training,
      title: 'Hose stretch',
      category: 'Training',
      date: now,
      roleOrAssignment: null,
      summary: 'Documented a training evolution.',
      impact: null,
      evidenceReference: null,
      hours: 2,
      repetitions: 1,
      tags: const ['training'],
      relatedGoalId: null,
      relatedRequirementId: null,
      relatedTaskId: null,
      highlight: false,
      trackingKey: null,
      outcome: null,
      createdAt: now,
      updatedAt: now,
    );

    expect(await store.upsert(record), isTrue);

    final reloaded = CareerRecordStore(
      store: LocalStore(fileStore: PlatformFileJsonStore(rootPath: dir.path)),
    );
    final loaded = await reloaded.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'Hose stretch');
    expect(
      File('${dir.path}/fireops.careerRecords.v2.2026.json').existsSync(),
      isTrue,
    );
  });

  test('restoreFromBytes reloads a portfolio backup file', () async {
    final dir = await Directory.systemTemp.createTemp('fireops_backup');
    addTearDown(() => dir.delete(recursive: true));
    final local = LocalStore(
      fileStore: PlatformFileJsonStore(rootPath: dir.path),
    );
    final source = CareerRecordStore(store: local);
    final backup = CareerBackupService(store: source);

    await local.saveProfile({'departmentName': 'Engine 6'});
    await local.setOnboardingComplete(true);
    final now = DateTime(2026, 1, 4, 9);
    await source.upsert(
      CareerRecord(
        id: 'call-1',
        type: CareerRecordType.operationalExperience,
        title: 'Working fire',
        category: 'Calls',
        date: now,
        roleOrAssignment: null,
        summary: null,
        impact: null,
        evidenceReference: null,
        hours: 1,
        repetitions: 1,
        tags: const ['call'],
        relatedGoalId: null,
        relatedRequirementId: null,
        relatedTaskId: null,
        highlight: true,
        trackingKey: null,
        outcome: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final json = await backup.exportBackupJson();
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['version'], 5);
    expect(decoded['format'], 'fireops-career-portfolio');

    final restoreDir = await Directory.systemTemp.createTemp('fireops_restore');
    addTearDown(() => restoreDir.delete(recursive: true));
    SharedPreferences.setMockInitialValues({});
    final restoredStore = CareerRecordStore(
      store: LocalStore(
        fileStore: PlatformFileJsonStore(rootPath: restoreDir.path),
      ),
    );
    final restored = await CareerBackupService(store: restoredStore)
        .restoreFromBytes(Uint8List.fromList(utf8.encode(json)));

    expect(restored.success, isTrue);
    expect(restored.count, 1);
    final records = await restoredStore.load();
    expect(records.single.title, 'Working fire');
  });

  test('restoreFromPastedJson still accepts a clipboard-style backup',
      () async {
    final dir = await Directory.systemTemp.createTemp('fireops_paste');
    addTearDown(() => dir.delete(recursive: true));
    final store = CareerRecordStore(
      store: LocalStore(
        fileStore: PlatformFileJsonStore(rootPath: dir.path),
      ),
    );
    final result = await CareerBackupService(store: store).restoreFromPastedJson(
      jsonEncode({
        'format': 'fireops-career-portfolio',
        'version': 5,
        'onboardingComplete': true,
        'profile': {'departmentName': 'Ladder 2'},
        'records': <Map<String, dynamic>>[],
        'certifications': <Map<String, dynamic>>[],
        'customRequirements': <Map<String, dynamic>>[],
        'pathOverrides': <Map<String, dynamic>>[],
      }),
    );
    expect(result.success, isTrue);
    final profile = await LocalStore(
      fileStore: PlatformFileJsonStore(rootPath: dir.path),
    ).loadProfile();
    expect(profile?['departmentName'], 'Ladder 2');
  });

  test('readBytesFromPath loads a backup sitting on disk', () async {
    final dir = await Directory.systemTemp.createTemp('fireops_path');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/FireOps-Career-Portfolio-2026-08-27.json');
    await file.writeAsString('{"format":"fireops-career-portfolio"}');
    final bytes = await readBytesFromPath(file.path);
    expect(bytes, isNotNull);
    expect(utf8.decode(bytes!), contains('fireops-career-portfolio'));
  });

  test('reset clears file-backed FireOps JSON and leaves other prefs', () async {
    SharedPreferences.setMockInitialValues({
      'unrelated.preference': 'keep',
    });
    final dir = await Directory.systemTemp.createTemp('fireops_reset');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalStore(
      fileStore: PlatformFileJsonStore(rootPath: dir.path),
    );
    await store.saveProfile({'departmentName': 'delete me'});
    expect(await store.resetAppData(), isTrue);
    expect(await store.loadProfile(), isNull);
    expect(dir.listSync(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('unrelated.preference'), 'keep');
  });
}
