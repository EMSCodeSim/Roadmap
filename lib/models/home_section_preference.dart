import 'package:flutter/material.dart';

enum HomeSectionType {
  goal,
  nextStep,
  needsAttention,
  careerSnapshot,
  jobSearch,
  dailyQuiz,
  trainingIdeas,
  department,
}

extension HomeSectionTypeX on HomeSectionType {
  String get label => switch (this) {
        HomeSectionType.goal => 'Career goal',
        HomeSectionType.nextStep => 'Next best step',
        HomeSectionType.needsAttention => 'Needs attention',
        HomeSectionType.careerSnapshot => 'Career snapshot',
        HomeSectionType.jobSearch => 'Job search findings',
        HomeSectionType.dailyQuiz => 'Daily quiz',
        HomeSectionType.trainingIdeas => 'Training ideas',
        HomeSectionType.department => 'Department',
      };

  String get description => switch (this) {
        HomeSectionType.goal => 'Your current career destination and plan',
        HomeSectionType.nextStep => 'The most useful action to take next',
        HomeSectionType.needsAttention =>
          'Credential renewals and unfinished follow-ups',
        HomeSectionType.careerSnapshot =>
          'Monthly activity, training hours, and credentials',
        HomeSectionType.jobSearch =>
          'Verified jobs matching your saved requirements',
        HomeSectionType.dailyQuiz => 'A short EMS knowledge check each day',
        HomeSectionType.trainingIdeas =>
          'Fire and EMS drills, scenarios, and practice',
        HomeSectionType.department =>
          'Department actions and unread updates when connected',
      };

  IconData get icon => switch (this) {
        HomeSectionType.goal => Icons.flag_outlined,
        HomeSectionType.nextStep => Icons.auto_awesome_outlined,
        HomeSectionType.needsAttention => Icons.notifications_active_outlined,
        HomeSectionType.careerSnapshot => Icons.insights_outlined,
        HomeSectionType.jobSearch => Icons.work_outline_rounded,
        HomeSectionType.dailyQuiz => Icons.quiz_outlined,
        HomeSectionType.trainingIdeas => Icons.school_outlined,
        HomeSectionType.department => Icons.apartment_outlined,
      };
}

class HomeSectionPreference {
  final HomeSectionType type;
  final bool visible;

  const HomeSectionPreference({required this.type, required this.visible});

  HomeSectionPreference copyWith({bool? visible}) => HomeSectionPreference(
        type: type,
        visible: visible ?? this.visible,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'visible': visible,
      };

  static HomeSectionPreference? fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    if (rawType == null) return null;
    HomeSectionType type;
    try {
      type = HomeSectionType.values.byName(rawType);
    } catch (_) {
      return null;
    }
    return HomeSectionPreference(
      type: type,
      visible: json['visible'] is bool ? json['visible'] as bool : true,
    );
  }
}
