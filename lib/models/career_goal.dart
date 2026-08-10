import 'package:firepath/models/requirement.dart';

class CareerGoal {
  final String id;
  final String title;
  final String category;
  final String description;
  final String? subtitle;
  final List<String> typicalPrerequisiteRoles;
  final List<Requirement> requirements;
  final List<Requirement> recommendedExperience;
  final List<String> resourceIds;
  final List<String> nextRoles;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareerGoal({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.subtitle,
    required this.typicalPrerequisiteRoles,
    required this.requirements,
    required this.recommendedExperience,
    required this.resourceIds,
    required this.nextRoles,
    required this.createdAt,
    required this.updatedAt,
  });
}
