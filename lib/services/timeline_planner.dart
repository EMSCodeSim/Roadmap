import 'package:flutter/foundation.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/models/user_profile.dart';
import 'package:firepath/state/app_state.dart';

enum TimelineItemKind { requirement, renewal, milestone, target }

class TimelineItem {
  final TimelineItemKind kind;
  final Requirement? requirement;
  final Certification? certification;
  final String title;
  final String? subtitle;
  final DateTime? fixedDate;
  final bool isNextStep;

  const TimelineItem({
    required this.kind,
    required this.requirement,
    required this.certification,
    required this.title,
    required this.subtitle,
    required this.fixedDate,
    required this.isNextStep,
  });
}

class TimelineSection {
  final String title;
  final String? hint;
  final List<TimelineItem> items;

  const TimelineSection({required this.title, required this.hint, required this.items});
}

class CareerTimelinePlan {
  final String goalTitle;
  final DateTime? targetReadyDate;
  final TimelineStatus status;
  final List<TimelineSection> sections;

  /// Up to ~3–5 major priorities for the current calendar year.
  final List<TimelineItem> thisYearPriorities;

  /// A single “current action” if one is obvious.
  final TimelineItem? thisMonthFocus;

  const CareerTimelinePlan({
    required this.goalTitle,
    required this.targetReadyDate,
    required this.status,
    required this.sections,
    required this.thisYearPriorities,
    required this.thisMonthFocus,
  });
}

class CareerTimelinePlanner {
  static TimelineStatus estimateStatus(AppState state) {
    final roadmap = state.roadmap;
    final target = state.profile.careerPlan.targetDate;
    if (roadmap == null || target == null || state.profile.careerPlan.timelineEnabled == false) return TimelineStatus.noTargetDate;
    return _statusForTimeline(state, roadmap, target);
  }

  static CareerTimelinePlan? build(AppState state) {
    final roadmap = state.roadmap;
    final goal = state.selectedGoal;
    if (roadmap == null || goal == null) return null;

    final plan = state.profile.careerPlan;
    final target = plan.targetDate;
    if (target == null || plan.timelineEnabled == false) {
      return CareerTimelinePlan(
        goalTitle: goal.title,
        targetReadyDate: null,
        status: TimelineStatus.noTargetDate,
        sections: const [],
        thisYearPriorities: const [],
        thisMonthFocus: null,
      );
    }

    final next = roadmap.nextStep?.requirement;
    final included = roadmap.included;
    final missing = roadmap.missing;

    final missingSorted = missing.toList();
    missingSorted.sort((a, b) {
      final ra = _rankRequirement(state, goal.id, a.requirement, isNext: next?.id == a.requirement.id);
      final rb = _rankRequirement(state, goal.id, b.requirement, isNext: next?.id == b.requirement.id);
      final c = ra.compareTo(rb);
      if (c != 0) return c;
      return a.requirement.sortOrder.compareTo(b.requirement.sortOrder);
    });

    // Build renewal items for certs that matter to this path.
    final renewalItems = _buildRenewals(state, included.map((e) => e.requirement).toList(), target);

    // Ongoing / span requirements.
    final ongoing = <TimelineItem>[];
    final finalPrep = <TimelineItem>[];

    // Stage buckets.
    final now = <TimelineItem>[];
    final nextUp = <TimelineItem>[];
    final then = <TimelineItem>[];
    final afterThat = <TimelineItem>[];

    // Completed milestones.
    final milestones = roadmap.completed.take(6).map((e) {
      return TimelineItem(
        kind: TimelineItemKind.milestone,
        requirement: e.requirement,
        certification: null,
        title: e.requirement.name,
        subtitle: 'Completed',
        fixedDate: null,
        isNextStep: false,
      );
    }).toList();

    for (final item in missingSorted) {
      final req = item.requirement;
      final o = state.getOverride(goal.id, req.id);
      if (o?.removedFromTimeline == true) continue;

      final schedule = state.scheduleFor(goalId: goal.id, requirementId: req.id);
      final fixed = schedule?.startDate ?? o?.suggestedStartDate ?? req.suggestedStartDate;
      final isNext = next != null && next.id == req.id;

      final ti = TimelineItem(
        kind: TimelineItemKind.requirement,
        requirement: req,
        certification: null,
        title: req.name,
        subtitle: _subtitleFor(state, goal.id, req, fixedDate: fixed, targetDate: target),
        fixedDate: fixed,
        isNextStep: isNext,
      );

      if (req.type == RequirementType.experience || req.type == RequirementType.numericProgress) {
        ongoing.add(ti);
        continue;
      }
      if (req.type == RequirementType.taskBook) {
        finalPrep.add(ti);
        continue;
      }

      if (isNext) {
        now.add(ti);
        continue;
      }
      final status = state.activityStatusFor(goalId: goal.id, requirementId: req.id);
      if (status == RequirementActivityStatus.inProgress || status == RequirementActivityStatus.scheduled || status == RequirementActivityStatus.planning) {
        now.add(ti);
        continue;
      }

      // Spread remaining requirements into simple buckets (no fake precision).
      if (nextUp.length < 1) {
        nextUp.add(ti);
      } else if (then.length < 2) {
        then.add(ti);
      } else {
        afterThat.add(ti);
      }
    }

    // Ensure NEXT STEP always appears somewhere.
    if (next != null && now.where((e) => e.requirement?.id == next.id).isEmpty && roadmap.missing.any((e) => e.requirement.id == next.id)) {
      now.insert(
        0,
        TimelineItem(
          kind: TimelineItemKind.requirement,
          requirement: next,
          certification: null,
          title: next.name,
          subtitle: _subtitleFor(state, goal.id, next, fixedDate: state.scheduleFor(goalId: goal.id, requirementId: next.id)?.startDate, targetDate: target),
          fixedDate: state.scheduleFor(goalId: goal.id, requirementId: next.id)?.startDate,
          isNextStep: true,
        ),
      );
    }

    // Build sections.
    final sections = <TimelineSection>[];
    sections.add(TimelineSection(title: goal.title.toUpperCase(), hint: 'Target Ready: ${_fmtMonthYear(target)}', items: const []));

    if (milestones.isNotEmpty) {
      sections.add(TimelineSection(title: 'NOW', hint: 'What you already have', items: milestones));
    }
    if (now.isNotEmpty) {
      sections.add(TimelineSection(title: 'NEXT', hint: 'Start now', items: now));
    }
    if (nextUp.isNotEmpty) {
      sections.add(TimelineSection(title: 'THEN', hint: 'Next 3–6 months', items: nextUp));
    }
    if (then.isNotEmpty) {
      sections.add(TimelineSection(title: 'AFTER THAT', hint: '6–12 months', items: then));
    }
    if (afterThat.isNotEmpty) {
      sections.add(TimelineSection(title: 'LATER', hint: 'As opportunities and schedules allow', items: afterThat));
    }
    if (ongoing.isNotEmpty) {
      sections.add(TimelineSection(title: 'ONGOING EXPERIENCE', hint: 'Continue throughout your timeline', items: ongoing.map((e) => _withPaceHint(e, state, goal.id, target)).toList()));
    }
    if (finalPrep.isNotEmpty) {
      sections.add(TimelineSection(title: 'FINAL PREPARATION', hint: 'Complete before your target ready date', items: finalPrep.map((e) => _withTaskBookPaceHint(e, state, goal.id, target)).toList()));
    }
    if (renewalItems.isNotEmpty) {
      sections.add(TimelineSection(title: 'RENEWAL NEEDED', hint: 'Expires before your target date', items: renewalItems));
    }

    sections.add(
      TimelineSection(
        title: 'TARGET',
        hint: 'Career Readiness Goal',
        items: [
          TimelineItem(
            kind: TimelineItemKind.target,
            requirement: null,
            certification: null,
            title: '${goal.title} Ready',
            subtitle: _fmtMonthYear(target),
            fixedDate: target,
            isNextStep: false,
          ),
        ],
      ),
    );

    final status = _statusForTimeline(state, roadmap, target);
    final yearPriorities = _buildYearPriorities(state, goal.id, roadmap, target);
    final monthFocus = next == null
        ? null
        : TimelineItem(
            kind: TimelineItemKind.requirement,
            requirement: next,
            certification: null,
            title: next.name,
            subtitle: _subtitleFor(state, goal.id, next, fixedDate: state.scheduleFor(goalId: goal.id, requirementId: next.id)?.startDate, targetDate: target),
            fixedDate: state.scheduleFor(goalId: goal.id, requirementId: next.id)?.startDate,
            isNextStep: true,
          );

    return CareerTimelinePlan(
      goalTitle: goal.title,
      targetReadyDate: target,
      status: status,
      sections: sections,
      thisYearPriorities: yearPriorities,
      thisMonthFocus: monthFocus,
    );
  }

  static List<TimelineItem> _buildRenewals(AppState state, List<Requirement> requirements, DateTime target) {
    final requiredCertIds = requirements
        .where((r) => r.type == RequirementType.certification)
        .map((r) => r.certificationDefinitionId)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet();

    final relevantCerts = state.certifications.where((c) => c.certificationDefinitionId != null && requiredCertIds.contains(c.certificationDefinitionId));

    final items = <TimelineItem>[];
    for (final cert in relevantCerts) {
      final exp = cert.expirationDate;
      if (exp == null || cert.doesNotExpire) continue;
      if (!exp.isBefore(target)) continue;
      items.add(
        TimelineItem(
          kind: TimelineItemKind.renewal,
          requirement: null,
          certification: cert,
          title: 'Renew ${state.certificationDisplayName(cert)}',
          subtitle: 'Expires ${_fmtMonthYear(exp)} — renew before your target ready date.',
          fixedDate: exp,
          isNextStep: false,
        ),
      );
    }
    items.sort((a, b) => (a.fixedDate ?? target).compareTo(b.fixedDate ?? target));
    return items;
  }

  static int _rankRequirement(AppState state, String goalId, Requirement r, {required bool isNext}) {
    final activity = state.activityStatusFor(goalId: goalId, requirementId: r.id);
    final scheduled = state.scheduleFor(goalId: goalId, requirementId: r.id);

    int baseTier() {
      final isCoreLike = r.priority == RequirementPriority.core || r.priority == RequirementPriority.state;
      final isDept = r.priority == RequirementPriority.department || r.requirementSource == RequirementSource.departmentRequirement;
      if (isCoreLike) return 10;
      if (isDept) return 20;
      if (r.priority == RequirementPriority.recommended) return 40;
      return 60;
    }

    int typeAdj() {
      if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) return 30;
      if (r.type == RequirementType.taskBook) return 35;
      return 0;
    }

    int activityAdj() {
      if (isNext) return -50;
      if (activity == RequirementActivityStatus.scheduled) return -40;
      if (scheduled?.startDate != null) return -35;
      if (activity == RequirementActivityStatus.inProgress) return -30;
      if (activity == RequirementActivityStatus.planning) return -10;
      return 0;
    }

    return baseTier() + typeAdj() + activityAdj();
  }

  static TimelineStatus _statusForTimeline(AppState state, Roadmap roadmap, DateTime target) {
    final goalId = roadmap.goal.id;
    final missing = roadmap.missing.map((e) => e.requirement).toList();

    bool hasScheduledAfterTarget = false;
    for (final r in missing) {
      final sched = state.scheduleFor(goalId: goalId, requirementId: r.id);
      if (sched?.startDate != null && sched!.startDate!.isAfter(target)) {
        hasScheduledAfterTarget = true;
        break;
      }
    }

    final renewals = _buildRenewals(state, roadmap.included.map((e) => e.requirement).toList(), target);
    final now = DateTime.now();
    final monthsLeft = _monthsBetween(DateTime(now.year, now.month, 1), DateTime(target.year, target.month, 1));
    final coreMissing = roadmap.missingCore.length;
    final majorMissing = roadmap.missing.where((e) {
      final r = e.requirement;
      if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) return false;
      if (r.priority == RequirementPriority.development) return false;
      return true;
    }).length;

    if (hasScheduledAfterTarget) return TimelineStatus.atRisk;
    if (monthsLeft <= 6 && (coreMissing >= 2 || majorMissing >= 4)) return TimelineStatus.atRisk;
    if (monthsLeft <= 12 && (coreMissing >= 2 || majorMissing >= 5)) return TimelineStatus.needsAttention;
    if (renewals.isNotEmpty) {
      // Renewal planning is important — but don't panic users.
      final earliest = renewals.first.fixedDate;
      if (earliest != null && target.difference(earliest).inDays >= 120) return TimelineStatus.needsAttention;
    }
    return TimelineStatus.onTrack;
  }

  static List<TimelineItem> _buildYearPriorities(AppState state, String goalId, Roadmap roadmap, DateTime target) {
    final items = <TimelineItem>[];
    final next = roadmap.nextStep?.requirement;
    if (next != null) {
      items.add(
        TimelineItem(
          kind: TimelineItemKind.requirement,
          requirement: next,
          certification: null,
          title: next.name,
          subtitle: 'Your next step',
          fixedDate: state.scheduleFor(goalId: goalId, requirementId: next.id)?.startDate,
          isNextStep: true,
        ),
      );
    }
    for (final e in roadmap.missing) {
      if (items.length >= 5) break;
      final r = e.requirement;
      if (next?.id == r.id) continue;
      if (r.priority == RequirementPriority.development) continue;
      if (r.type == RequirementType.experience || r.type == RequirementType.numericProgress) {
        items.add(
          TimelineItem(
            kind: TimelineItemKind.requirement,
            requirement: r,
            certification: null,
            title: r.name,
            subtitle: 'Ongoing',
            fixedDate: null,
            isNextStep: false,
          ),
        );
        continue;
      }
      items.add(
        TimelineItem(
          kind: TimelineItemKind.requirement,
          requirement: r,
          certification: null,
          title: r.name,
          subtitle: _subtitleFor(state, goalId, r, fixedDate: state.scheduleFor(goalId: goalId, requirementId: r.id)?.startDate, targetDate: target),
          fixedDate: state.scheduleFor(goalId: goalId, requirementId: r.id)?.startDate,
          isNextStep: false,
        ),
      );
    }
    return items;
  }

  static TimelineItem _withPaceHint(TimelineItem item, AppState state, String goalId, DateTime target) {
    final r = item.requirement;
    if (r == null) return item;
    if (r.type != RequirementType.numericProgress) return item;
    final current = r.progressCurrent ?? 0;
    final required = r.progressRequired ?? 0;
    final remaining = (required - current).clamp(0, double.infinity);
    if (remaining <= 0) return item;

    final now = DateTime.now();
    final monthsLeft = _monthsBetween(DateTime(now.year, now.month, 1), DateTime(target.year, target.month, 1));
    if (monthsLeft <= 0) return item;
    final pace = remaining / monthsLeft;
    final unit = (r.progressUnit ?? '').trim();
    final paceLabel = '${pace.toStringAsFixed(pace < 10 ? 1 : 0)}${unit.isEmpty ? '' : ' $unit'}/month';
    return TimelineItem(
      kind: item.kind,
      requirement: item.requirement,
      certification: item.certification,
      title: item.title,
      subtitle: '${item.subtitle ?? ''}${item.subtitle == null ? '' : '\n'}Suggested pace: ~$paceLabel',
      fixedDate: item.fixedDate,
      isNextStep: item.isNextStep,
    );
  }

  static TimelineItem _withTaskBookPaceHint(TimelineItem item, AppState state, String goalId, DateTime target) {
    final r = item.requirement;
    if (r == null || r.type != RequirementType.taskBook) return item;
    final prog = state.taskBookProgressFor(goalId: goalId, requirementId: r.id);
    if (prog == null) return item;
    final remaining = (prog.$2 - prog.$1);
    if (remaining <= 0) return item;

    final now = DateTime.now();
    final monthsLeft = _monthsBetween(DateTime(now.year, now.month, 1), DateTime(target.year, target.month, 1));
    if (monthsLeft <= 0) return item;
    final pace = remaining / monthsLeft;
    if (pace < 0.25) return item;
    final paceLabel = pace >= 1 ? '${pace.toStringAsFixed(0)} item/month' : '${pace.toStringAsFixed(1)} item/month';
    return TimelineItem(
      kind: item.kind,
      requirement: item.requirement,
      certification: item.certification,
      title: item.title,
      subtitle: '${item.subtitle ?? ''}${item.subtitle == null ? '' : '\n'}Suggested pace: ~$paceLabel',
      fixedDate: item.fixedDate,
      isNextStep: item.isNextStep,
    );
  }

  static String _subtitleFor(AppState state, String goalId, Requirement r, {required DateTime? fixedDate, required DateTime targetDate}) {
    final status = state.activityStatusFor(goalId: goalId, requirementId: r.id);
    final statusLabel = switch (status) {
      RequirementActivityStatus.planning => 'Planning',
      RequirementActivityStatus.scheduled => 'Scheduled',
      RequirementActivityStatus.inProgress => 'In Progress',
      RequirementActivityStatus.notStarted => 'Not Started',
    };

    final when = fixedDate == null
        ? null
        : fixedDate.isAfter(targetDate)
            ? 'Scheduled ${_fmtMonthYear(fixedDate)} (after target)'
            : 'Scheduled ${_fmtMonthYear(fixedDate)}';

    final parts = <String>[];
    parts.add(statusLabel);
    if (when != null) parts.add(when);
    if (r.priority == RequirementPriority.core || r.priority == RequirementPriority.state) parts.add('Core readiness');
    if (r.priority == RequirementPriority.recommended) parts.add('Recommended');
    if (r.priority == RequirementPriority.department) parts.add('Department dependent');
    return parts.join(' • ');
  }

  static int _monthsBetween(DateTime a, DateTime b) {
    final ay = a.year * 12 + a.month;
    final by = b.year * 12 + b.month;
    return (by - ay).clamp(-1200, 1200);
  }

  static String _fmtMonthYear(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }
}
