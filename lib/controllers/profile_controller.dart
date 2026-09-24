import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_path.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/state_requirement_catalog.dart';
import 'package:firepath/services/state_fire_authority_catalog.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/services/local_store.dart';
import 'package:firepath/services/task_book_setup_store.dart';

/// Owns and persists the user profile + onboarding flags.
///
/// This controller is intentionally UI-agnostic and can be unit-tested.
class ProfileController extends ChangeNotifier {
  ProfileController({LocalStore? store, TaskBookSetupStore? taskBookSetupStore})
      : _store = store ?? LocalStore(),
        _taskBookSetupStore = taskBookSetupStore ?? TaskBookSetupStore();

  final LocalStore _store;
  final TaskBookSetupStore _taskBookSetupStore;

  bool _onboardingComplete = false;
  UserProfile _profile = UserProfile.empty();

  bool get onboardingComplete => _onboardingComplete;
  UserProfile get profile => _profile;

  /// Goals available for the user's Personal career path (Fire / EMS / Both).
  List<CareerGoal> get availableGoals =>
      FireOpsCatalog.goalsForPath(_profile.effectiveCareerPath);

  CareerGoal? selectedGoal() {
    final id = _profile.primaryGoalId;
    if (id == null) return null;
    // Prefer path-filtered goals, but still resolve a goal the user already
    // selected even if they later switch paths (progress is never deleted).
    final fromPath =
        availableGoals.where((g) => g.id == id).cast<CareerGoal?>().firstOrNull;
    if (fromPath != null) return fromPath;
    final fromAll = FireOpsCatalog.goals()
        .where((g) => g.id == id)
        .cast<CareerGoal?>()
        .firstOrNull;
    if (fromAll != null) return fromAll;

    if (id.startsWith('custom:')) {
      final name = id.substring('custom:'.length).trim();
      final now = DateTime.now();
      return CareerGoal(
        id: id,
        title: name.isEmpty ? 'Custom Goal' : name,
        category: 'Custom',
        description: 'A custom goal you created.',
        subtitle: null,
        typicalPrerequisiteRoles: const [],
        requirements: const [],
        recommendedExperience: const [],
        resourceIds: const [],
        nextRoles: const [],
        createdAt: now,
        updatedAt: now,
      );
    }
    return null;
  }

  /// Returns the selected goal resolved for the user's selected state.
  ///
  /// Fire Operations and EMS ladder goals are cumulative. A user targeting a
  /// later stage receives requirements from earlier stages on the same ladder.
  /// Specialty EMS goals remain single-stage so branches can expand later.
  ///
  /// Existing certifications still satisfy matching requirements normally.
  CareerGoal? selectedGoalResolved() {
    final target = selectedGoal();
    if (target == null) return null;

    final stages = _careerStagesThrough(target);
    final stateCode = FireOpsCatalog.stateCodeFromLegacyValue(_profile.state);
    if (stateCode == null || stateCode == FireOpsCatalog.otherStateCode) {
      return _combineCareerStages(target, stages);
    }

    final stateName = FireOpsCatalog.stateNameForCode(stateCode) ?? stateCode;
    final resolvedStages = stages
        .map((stage) => _resolveSingleGoalForState(stage, stateCode, stateName))
        .toList();
    return _combineCareerStages(target, resolvedStages);
  }

  List<CareerGoal> _careerStagesThrough(CareerGoal target) {
    final ladder = FireOpsCatalog.ladderContaining(target.id);
    if (ladder == null) return <CareerGoal>[target];

    final targetIndex = ladder.indexOf(target.id);
    if (targetIndex < 0) return <CareerGoal>[target];

    final byId = <String, CareerGoal>{
      for (final goal in FireOpsCatalog.goals()) goal.id: goal,
    };
    return ladder
        .take(targetIndex + 1)
        .map((id) => byId[id])
        .whereType<CareerGoal>()
        .toList();
  }

  CareerGoal _combineCareerStages(
    CareerGoal target,
    List<CareerGoal> stages,
  ) {
    if (stages.length <= 1) return stages.isEmpty ? target : stages.first;

    final requirements = <Requirement>[];
    final seenRequirementIds = <String>{};
    for (var stageIndex = 0; stageIndex < stages.length; stageIndex++) {
      final stage = stages[stageIndex];
      for (final requirement in stage.requirements) {
        if (!seenRequirementIds.add(requirement.id)) continue;
        requirements.add(
          requirement.copyWith(
            sortOrder: (stageIndex * 100) + requirement.sortOrder,
          ),
        );
      }
    }

    return CareerGoal(
      id: target.id,
      title: target.title,
      category: target.category,
      description: target.description,
      subtitle: target.subtitle,
      typicalPrerequisiteRoles: target.typicalPrerequisiteRoles,
      requirements: requirements,
      recommendedExperience: target.recommendedExperience,
      resourceIds: target.resourceIds,
      nextRoles: target.nextRoles,
      createdAt: target.createdAt,
      updatedAt: target.updatedAt,
    );
  }

  CareerGoal _resolveSingleGoalForState(
    CareerGoal existing,
    String stateCode,
    String stateName,
  ) {
    final applicableBase = existing.requirements
        .where((r) {
          if (r.requirementSource != RequirementSource.stateRequirement) {
            final sourcedState = r.sourceStateCode?.trim().toUpperCase();
            return sourcedState == null ||
                sourcedState.isEmpty ||
                sourcedState == stateCode;
          }

          // Official/state-requirement entries must identify the state they
          // belong to. Never let an unscoped or foreign state rule bleed into
          // another user's roadmap.
          final sourcedState = r.sourceStateCode?.trim().toUpperCase();
          return sourcedState != null &&
              sourcedState.isNotEmpty &&
              sourcedState == stateCode;
        })
        .map((r) => _withStateContext(r, stateCode, stateName))
        .toList();

    // Use each ladder stage's original base catalog as the lookup source so a
    // verified state overlay can replace the correct common requirement even
    // when the user's final goal is several promotions beyond this stage.
    final baseById = {for (final r in existing.requirements) r.id: r};
    final verified = StateRequirementCatalog.buildVerifiedRequirements(
      stateCode: stateCode,
      careerGoalId: existing.id,
      baseRequirementById: baseById,
    );

    final merged = [...applicableBase];
    for (final r in verified) {
      final idx = merged.indexWhere((e) => e.id == r.id);
      if (idx >= 0) {
        merged[idx] = r;
      } else {
        merged.add(r);
      }
    }
    merged.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return CareerGoal(
      id: existing.id,
      title: existing.title,
      category: existing.category,
      description: existing.description,
      subtitle: existing.subtitle,
      typicalPrerequisiteRoles: existing.typicalPrerequisiteRoles,
      requirements: merged,
      recommendedExperience: existing.recommendedExperience,
      resourceIds: existing.resourceIds,
      nextRoles: existing.nextRoles,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
    );
  }

  Requirement _withStateContext(
    Requirement requirement,
    String stateCode,
    String stateName,
  ) {
    if (!requirement.stateDependent ||
        requirement.requirementSource == RequirementSource.stateRequirement) {
      return requirement;
    }

    final authority = StateFireAuthorityCatalog.forState(stateCode);
    const marker = 'State-specific note:';
    final baseDescription = requirement.description.contains(marker)
        ? requirement.description.split(marker).first.trimRight()
        : requirement.description.trimRight();

    final authorityGuidance = authority?.guidance ??
        'Confirm the current $stateName certification/training rules and your department requirements before treating this item as mandatory.';
    final description =
        '$baseDescription\n\n$marker $authorityGuidance';

    return requirement.copyWith(
      description: description,
      stateDependent: true,
      sourceStateCode: stateCode,
      sourceTitle: authority?.sourceTitle,
      sourceUrl: authority?.sourceUrl,
      sourceVerifiedDate: authority?.verifiedDate,
      sourceNotes: authorityGuidance,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> bootstrap() async {
    _onboardingComplete = await _store.getOnboardingComplete();
    final profileJson = await _store.loadProfile();
    _profile =
        profileJson == null ? UserProfile.empty() : UserProfile.fromJson(profileJson);

    // Silent migration: normalize state to a canonical code.
    final normalizedState = FireOpsCatalog.stateCodeFromLegacyValue(_profile.state);
    if (normalizedState != _profile.state) {
      _profile = _profile.copyWith(state: normalizedState);
      await _store.saveProfile(_profile.toJson());
    }

    // Keep a record for state-change detection prompts.
    try {
      final last = await _taskBookSetupStore.lastKnownState();
      if ((last ?? '').trim().isEmpty &&
          (normalizedState ?? '').trim().isNotEmpty) {
        await _taskBookSetupStore.setLastKnownState(normalizedState);
      }
    } catch (e) {
      debugPrint('ProfileController.bootstrap lastKnownState init failed: $e');
    }
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    await _store.setOnboardingComplete(value);
    notifyListeners();
  }

  Future<void> setProfile(UserProfile profile) async {
    _profile = profile.copyWith(updatedAt: DateTime.now());
    await _store.saveProfile(_profile.toJson());
    notifyListeners();
  }

  Future<void> setTimelineStatusIfDifferent(TimelineStatus status) async {
    if (_profile.careerPlan.timelineStatus == status) return;
    _profile = _profile.copyWith(
      careerPlan: _profile.careerPlan.copyWith(timelineStatus: status),
      updatedAt: DateTime.now(),
    );
    await _store.saveProfile(_profile.toJson());
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final before = _profile;
    await setProfile(profile);

    final oldState = FireOpsCatalog.stateCodeFromLegacyValue(before.state);
    final newState = FireOpsCatalog.stateCodeFromLegacyValue(_profile.state);
    if (_onboardingComplete &&
        oldState != null &&
        newState != null &&
        oldState.isNotEmpty &&
        newState.isNotEmpty &&
        oldState != newState) {
      try {
        await _taskBookSetupStore.setLastKnownState(newState);
        await _taskBookSetupStore.setReviewPending(true);
      } catch (e) {
        debugPrint(
            'ProfileController.updateProfile state-change flag failed: $e');
      }
    }
  }

  Future<void> setCurrentRoles(List<String> roles) =>
      updateProfile(_profile.copyWith(currentRoles: roles, updatedAt: DateTime.now()));

  /// Updates Personal career path without deleting logs, certs, or progress.
  Future<void> setCareerPath({
    required CareerPath careerPath,
    CareerPath? primaryTrack,
    bool confirmed = true,
  }) async {
    CareerPath? track = primaryTrack;
    if (careerPath == CareerPath.both) {
      track ??= _profile.primaryTrack ?? CareerPath.fire;
      if (track != CareerPath.fire && track != CareerPath.ems) {
        track = CareerPath.fire;
      }
    } else {
      track = null;
    }
    await updateProfile(
      _profile.copyWith(
        careerPath: careerPath,
        primaryTrack: track,
        clearPrimaryTrack: careerPath != CareerPath.both,
        careerPathConfirmed: confirmed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setPrimaryGoal(String goalId) async {
    final now = DateTime.now();
    final existingPlan = _profile.careerPlan;
    final shouldResetStart = existingPlan.goalId != goalId;
    final plan = existingPlan.copyWith(
      goalId: goalId,
      startDate: shouldResetStart ? now : existingPlan.startDate,
      timelineEnabled: existingPlan.targetDate != null,
      timelineStatus: existingPlan.targetDate == null
          ? TimelineStatus.noTargetDate
          : existingPlan.timelineStatus,
    );
    await updateProfile(
        _profile.copyWith(primaryGoalId: goalId, careerPlan: plan, updatedAt: now));
  }

  Future<void> setTargetReadyDate(DateTime? targetDate) async {
    final now = DateTime.now();
    final plan = _profile.careerPlan.copyWith(
      targetDate: targetDate,
      timelineEnabled: targetDate != null,
      timelineStatus: targetDate == null
          ? TimelineStatus.noTargetDate
          : _profile.careerPlan.timelineStatus,
      clearTargetDate: targetDate == null,
    );
    await updateProfile(_profile.copyWith(careerPlan: plan, updatedAt: now));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
