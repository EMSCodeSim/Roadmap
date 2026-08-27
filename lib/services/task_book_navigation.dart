import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/advanced_certification_guide_data.dart';
import 'package:firepath/services/certification_guide_library.dart';
import 'package:firepath/services/national_task_book_baseline.dart';
import 'package:firepath/services/task_book_library.dart';

/// Where a Task Book requirement should open.
///
/// Certifications open their JPR/skills checklist first. Preparation-task
/// books (Learn / Practice / Record) remain available as a secondary layer
/// when FireOps has authored that content.
enum TaskBookOpenTarget {
  skillsChecklist,
  preparationTasks,
  requirementDetail,
}

class TaskBookRouteArgs {
  final Requirement? requirement;
  final String? goalId;

  const TaskBookRouteArgs({this.requirement, this.goalId});

  factory TaskBookRouteArgs.fromExtra(Object? extra) {
    if (extra is Requirement) {
      return TaskBookRouteArgs(requirement: extra);
    }
    if (extra is Map) {
      final req = extra['requirement'];
      return TaskBookRouteArgs(
        requirement: req is Requirement ? req : null,
        goalId: extra['goalId'] as String?,
      );
    }
    return const TaskBookRouteArgs();
  }
}

class TaskBookNavigation {
  TaskBookNavigation._();

  static bool hasSkillsChecklist(Requirement requirement) {
    return requirement.type == RequirementType.certification ||
        NationalTaskBookBaseline.standardFor(requirement) != null;
  }

  static bool hasPreparationTasks(Requirement requirement) {
    return TaskBookLibrary.hasTasksForRequirement(requirement) ||
        CertificationGuideLibrary.guideForRequirement(requirement) != null ||
        AdvancedCertificationGuideData.forRequirement(requirement) != null;
  }

  static TaskBookOpenTarget targetFor(Requirement requirement) {
    if (hasSkillsChecklist(requirement)) {
      return TaskBookOpenTarget.skillsChecklist;
    }
    if (hasPreparationTasks(requirement)) {
      return TaskBookOpenTarget.preparationTasks;
    }
    return TaskBookOpenTarget.requirementDetail;
  }
}
