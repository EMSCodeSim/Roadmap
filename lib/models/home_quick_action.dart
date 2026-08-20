import 'package:flutter/material.dart';

/// A lightweight, user-configurable quick action shown on the Home screen.
///
/// Stored locally (SharedPreferences) and intended for fast, one-tap launches.
class HomeQuickAction {
  final HomeQuickActionType type;

  /// Only used when [type] is [HomeQuickActionType.quickLogTemplate].
  ///
  /// Must match a [QuickLogTracker.keyName] from [QuickLogCatalog].
  final String? trackerKey;

  /// Optional user-facing label stored for stability (e.g., custom templates).
  final String? titleOverride;

  const HomeQuickAction({required this.type, this.trackerKey, this.titleOverride});

  factory HomeQuickAction.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?) ?? HomeQuickActionType.quickLog.name;
    HomeQuickActionType parsed;
    try {
      parsed = HomeQuickActionType.values.byName(rawType);
    } catch (_) {
      parsed = HomeQuickActionType.quickLog;
    }
    final trackerKey = (json['trackerKey'] as String?)?.trim();
    final titleOverride = (json['titleOverride'] as String?)?.trim();
    return HomeQuickAction(
      type: parsed,
      trackerKey: trackerKey?.isEmpty == true ? null : trackerKey,
      titleOverride: titleOverride?.isEmpty == true ? null : titleOverride,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (trackerKey != null) 'trackerKey': trackerKey,
        if (titleOverride != null) 'titleOverride': titleOverride,
      };

  HomeQuickAction copyWith({HomeQuickActionType? type, String? trackerKey, String? titleOverride}) =>
      HomeQuickAction(
        type: type ?? this.type,
        trackerKey: trackerKey ?? this.trackerKey,
        titleOverride: titleOverride ?? this.titleOverride,
      );

  bool get isValid => switch (type) {
        HomeQuickActionType.quickLogTemplate => (trackerKey ?? '').trim().isNotEmpty,
        _ => true,
      };
}

enum HomeQuickActionType {
  quickLog,
  dailyFocus,
  openTaskBook,
  openCerts,
  openResources,
  quickLogTemplate,
}

extension HomeQuickActionTypeX on HomeQuickActionType {
  IconData get icon => switch (this) {
        HomeQuickActionType.quickLog => Icons.add_task_outlined,
        HomeQuickActionType.dailyFocus => Icons.bolt_outlined,
        HomeQuickActionType.openTaskBook => Icons.menu_book_outlined,
        HomeQuickActionType.openCerts => Icons.verified_outlined,
        HomeQuickActionType.openResources => Icons.link_outlined,
        HomeQuickActionType.quickLogTemplate => Icons.bookmark_add_outlined,
      };

  String get label => switch (this) {
        HomeQuickActionType.quickLog => 'Quick Log',
        HomeQuickActionType.dailyFocus => 'Daily Focus',
        HomeQuickActionType.openTaskBook => 'Task Book',
        HomeQuickActionType.openCerts => 'Certs',
        HomeQuickActionType.openResources => 'Resources',
        HomeQuickActionType.quickLogTemplate => 'Quick Log template',
      };

  String get detail => switch (this) {
        HomeQuickActionType.quickLog => 'Pick a category',
        HomeQuickActionType.dailyFocus => 'Plan today',
        HomeQuickActionType.openTaskBook => 'Open your path',
        HomeQuickActionType.openCerts => 'Renewals & status',
        HomeQuickActionType.openResources => 'Links & guides',
        HomeQuickActionType.quickLogTemplate => 'One-tap log',
      };
}
