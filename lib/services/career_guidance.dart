import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/requirement_source_presenter.dart';
import 'package:firepath/services/smart_next_step.dart';
import 'package:firepath/state/app_state.dart';

class CareerGuidanceSummary {
  final String whyItMatters;
  final String requiredBy;
  final String nextActionTitle;
  final String nextActionDetail;
  final String nextActionLabel;
  final String unlocks;
  final String authorityNote;

  const CareerGuidanceSummary({
    required this.whyItMatters,
    required this.requiredBy,
    required this.nextActionTitle,
    required this.nextActionDetail,
    required this.nextActionLabel,
    required this.unlocks,
    required this.authorityNote,
  });
}

class CareerGuidanceEngine {
  CareerGuidanceEngine._();

  static CareerGuidanceSummary build({
    required AppState state,
    required CareerGoal goal,
    required Requirement requirement,
    required String goalId,
  }) {
    final action = SmartNextStepEngine.todayActionFor(
      state,
      goalId: goalId,
      requirement: requirement,
    );

    return CareerGuidanceSummary(
      whyItMatters: _why(goal, requirement),
      requiredBy: RequirementSourcePresenter.shortLine(
        requirement,
        profileStateCode: state.profile.state,
      ),
      nextActionTitle: action.$1,
      nextActionDetail: action.$2,
      nextActionLabel: action.$3,
      unlocks: _unlocks(goal, requirement),
      authorityNote: _authority(requirement),
    );
  }

  static String _why(CareerGoal goal, Requirement requirement) {
    final description = requirement.description.trim();
    if (description.isNotEmpty) return description;

    return switch (requirement.type) {
      RequirementType.certification =>
        '${requirement.name} is part of the preparation path toward ${goal.title} and may satisfy a credential prerequisite for later roles.',
      RequirementType.taskBook =>
        'This Task Book turns ${goal.title} readiness into observable work that can be practiced, evaluated, and documented.',
      RequirementType.practical =>
        'This practical verifies that knowledge can be performed consistently, not just understood.',
      RequirementType.promotionalTest =>
        'This testing step is part of demonstrating readiness for ${goal.title}.',
      RequirementType.experience =>
        'This experience builds repetition and judgment that cannot be replaced by classroom completion alone.',
      RequirementType.numericProgress =>
        'This requirement builds the volume of real practice or experience expected for ${goal.title}.',
      RequirementType.trainingCourse || RequirementType.course =>
        'This training provides knowledge or practice that supports readiness for ${goal.title}.',
      RequirementType.interview =>
        'This step helps demonstrate judgment, communication, and role readiness for ${goal.title}.',
      RequirementType.education =>
        'This education supports the knowledge base expected for ${goal.title}.',
      RequirementType.custom =>
        'This requirement was added to support your personal or department path toward ${goal.title}.',
    };
  }

  static String _unlocks(CareerGoal goal, Requirement requirement) {
    final nextRoles = goal.nextRoles.where((role) => role.trim().isNotEmpty).toList();
    if (nextRoles.isNotEmpty) {
      return 'Completing this requirement helps move you toward ${goal.title}. Completing the full ${goal.title} roadmap can position you for ${nextRoles.take(3).join(', ')}.';
    }
    return 'Completing this requirement removes one gap from your ${goal.title} roadmap and helps unlock the next incomplete requirement.';
  }

  static String _authority(Requirement requirement) {
    if (requirement.requirementSource == RequirementSource.departmentRequirement ||
        requirement.departmentDependent) {
      return 'Your department is the authority for whether this requirement is required and whether it grants operational authorization.';
    }
    if (requirement.requirementSource == RequirementSource.stateRequirement ||
        requirement.stateDependent) {
      return 'Verify the current requirement with the applicable state or certifying authority. Responder Roadmap records progress but does not issue the credential.';
    }
    if (requirement.type == RequirementType.certification ||
        requirement.type == RequirementType.practical ||
        requirement.type == RequirementType.promotionalTest) {
      return 'The applicable certifying, testing, or department authority determines the official passing or qualification result.';
    }
    return 'Responder Roadmap guides and records progress. Official qualification or authorization remains with the applicable department or authority.';
  }
}
