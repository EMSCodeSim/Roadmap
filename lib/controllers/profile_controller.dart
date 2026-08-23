import 'package:flutter/foundation.dart';

import 'package:firepath/models/career_goal.dart';
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

  List<CareerGoal> get availableGoals => FireOpsCatalog.goals();

  CareerGoal? selectedGoal() {
    final id = _profile.primaryGoalId;
    if (id == null) return null;
    final existing =
        availableGoals.where((g) => g.id == id).cast<CareerGoal?>().firstOrNull;
    if (existing != null) return existing;

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
  /// Rules:
  /// - A requirement sourced to one state is never shown to a user in another.
  /// - Verified state requirements replace their matching common requirement.
  /// - State-dependent common guidance is attached to the correct official
  ///   state fire-service authority so every state points at its own source.
  /// - Common guidance is never silently promoted to a legal/statewide mandate;
  ///   the source note tells the user when department/AHJ rules still control.
  CareerGoal? selectedGoalResolved() {
    final existing = selectedGoal();
    if (existing == null) return null;

    final stateCode = FireOpsCatalog.stateCodeFromLegacyValue(_profile.state);
    if (stateCode == null || stateCode == FireOpsCatalog.otherStateCode) {
      return existing;
    }

    final stateName = FireOpsCatalog.stateNameForCode(stateCode) ?? stateCode;

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

    // Use the original base catalog as the lookup source so a verified overlay
    // can still replace its common counterpart even when the common item had
    // legacy state metadata that was filtered above.
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
    _profile = profileJson == null ? UserProfile.empty() : UserProfile.fromJson(profileJson);

    // Silent migration: normalize state to a canonical code.
    final normalizedState = FireOpsCatalog.stateCodeFromLegacyValue(_profile.state);
    if (normalizedState != _profile.state) {
      _profile = _profile.copyWith(state: normalizedState);
      await _store.saveProfile(_profile.toJson());
    }

    // Keep a record for state-change detection prompts.
    try {
      final last = await _taskBookSetupStore.lastKnownState();
      if ((last ?? '').trim().isEmpty && (normalizedState ?? '').trim().isNotEmpty) {
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
        debugPrint('ProfileController.updateProfile state-change flag failed: $e');
      }
    }
  }

  Future<void> setCurrentRoles(List<String> roles) =>
      updateProfile(_profile.copyWith(currentRoles: roles, updatedAt: DateTime.now()));

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
    await updateProfile(_profile.copyWith(primaryGoalId: goalId, careerPlan: plan, updatedAt: now));
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
