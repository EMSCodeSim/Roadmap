import 'package:firepath/models/career_record.dart';

class QuickLogTemplate {
  final String id;
  final String title;
  final String category;
  final CareerRecordType type;
  final bool tracksOutcome;
  final String iconKey;
  final bool isCustom;

  const QuickLogTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.tracksOutcome,
    required this.iconKey,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'type': type.name,
        'tracksOutcome': tracksOutcome,
        'iconKey': iconKey,
        'isCustom': isCustom,
      };

  factory QuickLogTemplate.fromJson(Map<String, dynamic> json) {
    CareerRecordType parseType(dynamic value) {
      if (value is String) {
        try {
          return CareerRecordType.values.byName(value);
        } catch (_) {}
      }
      return CareerRecordType.operationalExperience;
    }

    return QuickLogTemplate(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Custom',
      type: parseType(json['type']),
      tracksOutcome: (json['tracksOutcome'] as bool?) ?? false,
      iconKey: (json['iconKey'] as String?) ?? 'custom',
      isCustom: (json['isCustom'] as bool?) ?? true,
    );
  }
}

class QuickLogPreferences {
  final List<String> pinnedIds;
  final List<QuickLogTemplate> customTemplates;
  /// Controls the tiles shown in the Quick Log sheet under "WHAT ARE YOU LOGGING?".
  ///
  /// Stored as stable string keys so it can be edited without importing UI enums.
  /// Valid keys: call, training, skill, drive, task_book, career
  final List<String> quickActionKeys;

  const QuickLogPreferences({
    required this.pinnedIds,
    required this.customTemplates,
    required this.quickActionKeys,
  });

  Map<String, dynamic> toJson() => {
        'pinnedIds': pinnedIds,
        'customTemplates': customTemplates.map((e) => e.toJson()).toList(),
        'quickActionKeys': quickActionKeys,
      };

  factory QuickLogPreferences.fromJson(Map<String, dynamic> json) {
    final pinnedRaw = json['pinnedIds'];
    final customRaw = json['customTemplates'];
    final quickRaw = json['quickActionKeys'];
    return QuickLogPreferences(
      pinnedIds: pinnedRaw is List ? pinnedRaw.whereType<String>().toList() : const <String>[],
      customTemplates: customRaw is List
          ? customRaw
              .whereType<Map>()
              .map((e) => QuickLogTemplate.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty && e.title.trim().isNotEmpty)
              .toList()
          : const <QuickLogTemplate>[],
      quickActionKeys:
          quickRaw is List ? quickRaw.whereType<String>().toList() : const <String>[],
    );
  }
}
