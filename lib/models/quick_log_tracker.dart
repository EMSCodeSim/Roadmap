import 'package:firepath/models/career_record.dart';

enum QuickLogRolePreset {
  medic,
  firefighter,
  engineer,
  officer,
}

extension QuickLogRolePresetX on QuickLogRolePreset {
  String get label => switch (this) {
        QuickLogRolePreset.medic => 'Medic',
        QuickLogRolePreset.firefighter => 'Firefighter',
        QuickLogRolePreset.engineer => 'Engineer / Driver',
        QuickLogRolePreset.officer => 'Officer',
      };

  String get description => switch (this) {
        QuickLogRolePreset.medic => 'Procedures, resuscitation, and advanced patient care',
        QuickLogRolePreset.firefighter => 'Fire, rescue, and company-level skills',
        QuickLogRolePreset.engineer => 'Driving, pumping, water supply, and apparatus work',
        QuickLogRolePreset.officer => 'Command, leadership, training, and crew development',
      };
}

class QuickLogTracker {
  final String keyName;
  final String title;
  final String category;
  final CareerRecordType type;
  final String iconName;
  final bool tracksOutcome;
  final bool custom;

  const QuickLogTracker({
    required this.keyName,
    required this.title,
    required this.category,
    required this.type,
    required this.iconName,
    this.tracksOutcome = false,
    this.custom = false,
  });

  Map<String, dynamic> toJson() => {
        'keyName': keyName,
        'title': title,
        'category': category,
        'type': type.name,
        'iconName': iconName,
        'tracksOutcome': tracksOutcome,
        'custom': custom,
      };

  factory QuickLogTracker.fromJson(Map<String, dynamic> json) {
    CareerRecordType type = CareerRecordType.operationalExperience;
    final rawType = json['type'];
    if (rawType is String) {
      try {
        type = CareerRecordType.values.byName(rawType);
      } catch (_) {}
    }
    return QuickLogTracker(
      keyName: (json['keyName'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      type: type,
      iconName: (json['iconName'] as String?) ?? 'add_task',
      tracksOutcome: (json['tracksOutcome'] as bool?) ?? false,
      custom: (json['custom'] as bool?) ?? false,
    );
  }
}

class QuickLogConfig {
  final QuickLogRolePreset? rolePreset;
  final List<String> pinnedKeys;
  final List<QuickLogTracker> customTrackers;

  const QuickLogConfig({
    required this.rolePreset,
    required this.pinnedKeys,
    required this.customTrackers,
  });

  Map<String, dynamic> toJson() => {
        'rolePreset': rolePreset?.name,
        'pinnedKeys': pinnedKeys,
        'customTrackers': customTrackers.map((e) => e.toJson()).toList(),
      };

  factory QuickLogConfig.fromJson(Map<String, dynamic> json) {
    QuickLogRolePreset? preset;
    final rawPreset = json['rolePreset'];
    if (rawPreset is String) {
      try {
        preset = QuickLogRolePreset.values.byName(rawPreset);
      } catch (_) {}
    }
    final rawKeys = json['pinnedKeys'];
    final rawCustom = json['customTrackers'];
    return QuickLogConfig(
      rolePreset: preset,
      pinnedKeys: rawKeys is List ? rawKeys.whereType<String>().toList() : const <String>[],
      customTrackers: rawCustom is List
          ? rawCustom
              .whereType<Map>()
              .map((e) => QuickLogTracker.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.keyName.isNotEmpty && e.title.isNotEmpty)
              .toList()
          : const <QuickLogTracker>[],
    );
  }
}

class QuickLogCatalog {
  static const List<QuickLogTracker> builtIns = [
    QuickLogTracker(keyName: 'ems.iv', title: 'IV', category: 'EMS skill', type: CareerRecordType.skill, iconName: 'vaccines', tracksOutcome: true),
    QuickLogTracker(keyName: 'ems.io', title: 'IO', category: 'EMS skill', type: CareerRecordType.skill, iconName: 'medical', tracksOutcome: true),
    QuickLogTracker(keyName: 'ems.airway', title: 'Advanced airway', category: 'Airway', type: CareerRecordType.skill, iconName: 'air', tracksOutcome: true),
    QuickLogTracker(keyName: 'ems.cardiac_arrest', title: 'Cardiac arrest', category: 'EMS call', type: CareerRecordType.operationalExperience, iconName: 'heart'),
    QuickLogTracker(keyName: 'ems.cardioversion', title: 'Cardioversion', category: 'EMS skill', type: CareerRecordType.skill, iconName: 'monitor', tracksOutcome: true),
    QuickLogTracker(keyName: 'ems.pacing', title: 'Pacing', category: 'EMS skill', type: CareerRecordType.skill, iconName: 'monitor'),
    QuickLogTracker(keyName: 'ems.cpap', title: 'CPAP', category: 'Airway', type: CareerRecordType.skill, iconName: 'air'),
    QuickLogTracker(keyName: 'ems.medication', title: 'Medication', category: 'EMS skill', type: CareerRecordType.skill, iconName: 'medication'),
    QuickLogTracker(keyName: 'fire.structure_fire', title: 'Structure fire', category: 'Fire call', type: CareerRecordType.operationalExperience, iconName: 'structure'),
    QuickLogTracker(keyName: 'fire.car_fire', title: 'Car fire', category: 'Fire call', type: CareerRecordType.operationalExperience, iconName: 'car'),
    QuickLogTracker(keyName: 'fire.wildland', title: 'Wildland fire', category: 'Fire call', type: CareerRecordType.operationalExperience, iconName: 'fire'),
    QuickLogTracker(keyName: 'fire.extrication', title: 'Extrication', category: 'Rescue', type: CareerRecordType.operationalExperience, iconName: 'crash'),
    QuickLogTracker(keyName: 'fire.hose', title: 'Hose / nozzle', category: 'Fire skill', type: CareerRecordType.skill, iconName: 'water'),
    QuickLogTracker(keyName: 'fire.ladders', title: 'Ladders', category: 'Fire skill', type: CareerRecordType.skill, iconName: 'ladder'),
    QuickLogTracker(keyName: 'fire.forcible_entry', title: 'Forcible entry', category: 'Fire skill', type: CareerRecordType.skill, iconName: 'tools'),
    QuickLogTracker(keyName: 'fire.search', title: 'Search', category: 'Fire skill', type: CareerRecordType.skill, iconName: 'search'),
    QuickLogTracker(keyName: 'fire.driver', title: 'Emergency driving', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'truck'),
    QuickLogTracker(keyName: 'fire.pump_ops', title: 'Pump operation', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'water'),
    QuickLogTracker(keyName: 'fire.hydrant', title: 'Hydrant supply', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'hydrant'),
    QuickLogTracker(keyName: 'fire.relay', title: 'Relay pumping', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'route'),
    QuickLogTracker(keyName: 'fire.master_stream', title: 'Master stream', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'water'),
    QuickLogTracker(keyName: 'fire.aerial', title: 'Aerial setup', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'ladder'),
    QuickLogTracker(keyName: 'fire.tender', title: 'Tender operation', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'truck'),
    QuickLogTracker(keyName: 'fire.apparatus_check', title: 'Apparatus check', category: 'Driver / Operator', type: CareerRecordType.skill, iconName: 'checklist'),
    QuickLogTracker(keyName: 'officer.acting', title: 'Acting officer shift', category: 'Leadership', type: CareerRecordType.leadership, iconName: 'groups'),
    QuickLogTracker(keyName: 'officer.command', title: 'Incident command', category: 'Leadership', type: CareerRecordType.leadership, iconName: 'command'),
    QuickLogTracker(keyName: 'officer.training', title: 'Training delivered', category: 'Training', type: CareerRecordType.teaching, iconName: 'school'),
    QuickLogTracker(keyName: 'officer.mentoring', title: 'Mentoring', category: 'Leadership', type: CareerRecordType.teaching, iconName: 'person'),
    QuickLogTracker(keyName: 'officer.personnel', title: 'Personnel issue', category: 'Leadership', type: CareerRecordType.leadership, iconName: 'groups'),
    QuickLogTracker(keyName: 'officer.project', title: 'Project / committee', category: 'Professional development', type: CareerRecordType.project, iconName: 'project'),
    QuickLogTracker(keyName: 'officer.community', title: 'Community event', category: 'Professional development', type: CareerRecordType.operationalExperience, iconName: 'community'),
    QuickLogTracker(keyName: 'officer.review', title: 'Performance review', category: 'Leadership', type: CareerRecordType.leadership, iconName: 'checklist'),
  ];

  static const Map<QuickLogRolePreset, List<String>> roleDefaults = {
    QuickLogRolePreset.medic: ['ems.iv', 'ems.io', 'ems.airway', 'ems.cardiac_arrest', 'ems.cardioversion', 'ems.pacing', 'ems.cpap', 'ems.medication'],
    QuickLogRolePreset.firefighter: ['fire.structure_fire', 'fire.car_fire', 'fire.wildland', 'fire.extrication', 'fire.hose', 'fire.ladders', 'fire.forcible_entry', 'fire.search'],
    QuickLogRolePreset.engineer: ['fire.driver', 'fire.pump_ops', 'fire.hydrant', 'fire.relay', 'fire.master_stream', 'fire.aerial', 'fire.tender', 'fire.apparatus_check'],
    QuickLogRolePreset.officer: ['officer.acting', 'officer.command', 'officer.training', 'officer.mentoring', 'officer.personnel', 'officer.project', 'officer.community', 'officer.review'],
  };

  static QuickLogTracker? byKey(String key, [List<QuickLogTracker> custom = const []]) {
    for (final tracker in [...custom, ...builtIns]) {
      if (tracker.keyName == key) return tracker;
    }
    return null;
  }

  static List<String> defaultsFor(QuickLogRolePreset preset) => List<String>.from(roleDefaults[preset] ?? const <String>[]);
}
