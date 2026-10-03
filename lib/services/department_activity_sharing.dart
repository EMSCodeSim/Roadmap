import 'package:firepath/models/career_record.dart';
import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

/// Keeps member-controlled personal activity sharing explicit and reversible.
///
/// Personal records stay local by default. Only records with
/// details['shareWithDepartment'] == true are sent to the connected department.
class DepartmentActivitySharingService {
  DepartmentActivitySharingService({
    CareerRecordStore? store,
    ResponderRoadmapApi? api,
  })  : _store = store ?? CareerRecordStore(),
        _api = api ?? ResponderRoadmapApi();

  final CareerRecordStore _store;
  final ResponderRoadmapApi _api;

  Future<void> sync() async {
    final records = await _store.load();
    final shared = records.where((record) => record.details['shareWithDepartment'] == true);
    await _api.syncSharedActivities(shared.map(_payload).toList(growable: false));
  }

  static Map<String, dynamic> _payload(CareerRecord record) => {
        'id': record.id,
        'type': record.type.name,
        'title': record.title,
        'category': record.category,
        'occurredAt': record.date.toIso8601String(),
        'hours': record.hours,
        'repetitions': record.repetitions,
        'detail': record.summary ?? '',
        'tags': record.tags,
        'updatedAt': record.updatedAt.toIso8601String(),
      };
}
